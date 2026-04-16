// ═══════════════════════════════════════════════════════════════════
// CALENDAR_SETTINGS_SCREEN.DART — Calendar & Date Settings
// All values read from and write to the settings provider.
// Changes persist immediately to Supabase.
// See SPEC.md §14.5 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/kitab_toast.dart';

class CalendarSettingsScreen extends ConsumerWidget {
  const CalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar & Date', style: KitabTypography.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KitabSpacing.lg),
        children: [
          // ─── Islamic Personalization ───
          SwitchListTile(
            title: const Text('Islamic Personalization'),
            subtitle: const Text('Enable Islamic greetings, Hijri dates, prayer time features'),
            value: settings.islamicPersonalization,
            onChanged: (v) {
              final updates = <String, dynamic>{'islamic_personalization': v};
              if (!v) updates['hijri_calendar_enabled'] = false;
              ref.read(userSettingsProvider.notifier).update(updates);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),

          // ─── Hijri Calendar ───
          SwitchListTile(
            title: const Text('Hijri Calendar'),
            subtitle: const Text('Show Hijri dates alongside Gregorian'),
            value: settings.hijriCalendarEnabled,
            onChanged: settings.islamicPersonalization
                ? (v) => ref.read(userSettingsProvider.notifier).update({'hijri_calendar_enabled': v})
                : null,
            contentPadding: EdgeInsets.zero,
          ),

          // ─── Hijri options (only when Hijri is enabled) ───
          if (settings.hijriCalendarEnabled) ...[
            const SizedBox(height: KitabSpacing.sm),

            DropdownButtonFormField<String>(
              value: settings.hijriMethod,
              decoration: const InputDecoration(labelText: 'Hijri Calculation Method'),
              items: const [
                DropdownMenuItem(value: 'umm_al_qura', child: Text('Umm al-Qura (Saudi Arabia)')),
                DropdownMenuItem(value: 'diyanet', child: Text('Diyanet (Turkey)')),
                DropdownMenuItem(value: 'islamic_society', child: Text('Islamic Society of North America')),
                DropdownMenuItem(value: 'astronomical', child: Text('Astronomical (Tabular)')),
              ],
              onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'hijri_method': v}),
            ),
            const SizedBox(height: KitabSpacing.xs),
            Text(
              'Determines how Hijri dates are calculated. All methods are purely algorithmic.',
              style: KitabTypography.caption.copyWith(color: KitabColors.gray500),
            ),
          ],

          if (settings.islamicPersonalization) ...[
            const Divider(),
            const SizedBox(height: KitabSpacing.md),
            Text('Prayer Calculation', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),

            DropdownButtonFormField<String>(
              value: settings.prayerCalculationMethod,
              decoration: const InputDecoration(labelText: 'Calculation Method'),
              items: const [
                DropdownMenuItem(value: 'isna', child: Text('ISNA (North America)')),
                DropdownMenuItem(value: 'mwl', child: Text('Muslim World League')),
                DropdownMenuItem(value: 'egyptian', child: Text('Egyptian General Authority')),
                DropdownMenuItem(value: 'umm_al_qura', child: Text('Umm al-Qura (Saudi Arabia)')),
                DropdownMenuItem(value: 'karachi', child: Text('University of Karachi')),
              ],
              onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'prayer_calculation_method': v}),
            ),
            const SizedBox(height: KitabSpacing.md),

            DropdownButtonFormField<String>(
              value: settings.prayerMadhab,
              decoration: const InputDecoration(labelText: 'Asr Calculation (Madhab)'),
              items: const [
                DropdownMenuItem(value: 'shafi', child: Text("Standard (Shafi'i, Hanbali, Maliki)")),
                DropdownMenuItem(value: 'hanafi', child: Text('Hanafi')),
              ],
              onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'prayer_madhab': v}),
            ),
            const Divider(),
            const SizedBox(height: KitabSpacing.md),

            // ─── Location for Prayer Times ───
            Text('Location', style: KitabTypography.h3),
            const SizedBox(height: KitabSpacing.sm),
            Text('Used for prayer time calculations and Day/Night display.',
                style: KitabTypography.bodySmall.copyWith(color: KitabColors.gray500)),
            const SizedBox(height: KitabSpacing.sm),

            // Location mode selector
            Consumer(builder: (context, ref, _) {
              final mode = settings.locationMode;
              return Column(
                children: [
                  // GPS option
                  RadioListTile<String>(
                    title: const Text('Use device location'),
                    subtitle: const Text('Automatic GPS-based location'),
                    value: 'gps',
                    groupValue: mode,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) async {
                      final service = ref.read(locationServiceProvider);
                      final granted = await service.requestPermission();
                      if (granted) {
                        ref.read(userSettingsProvider.notifier).update({'location_mode': v});
                        await service.getLocation(forceRefresh: true);
                        ref.invalidate(userLocationProvider);
                      } else if (context.mounted) {
                        KitabToast.error(context, 'Location permission denied. Check your browser/device settings.');
                      }
                    },
                  ),
                  // Manual city option
                  RadioListTile<String>(
                    title: const Text('Set location manually'),
                    subtitle: const Text('Search for a city'),
                    value: 'manual',
                    groupValue: mode,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      ref.read(userSettingsProvider.notifier).update({'location_mode': v});
                      ref.invalidate(userLocationProvider);
                    },
                  ),
                  // Off option
                  RadioListTile<String>(
                    title: const Text('Off'),
                    subtitle: const Text('Prayer times will use approximate defaults'),
                    value: 'off',
                    groupValue: mode,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      ref.read(userSettingsProvider.notifier).update({'location_mode': v});
                      ref.invalidate(userLocationProvider);
                    },
                  ),
                ],
              );
            }),

            // Location status / city display
            Consumer(builder: (context, ref, _) {
              final mode = settings.locationMode;

              if (mode == 'off') {
                return Padding(
                  padding: const EdgeInsets.only(top: KitabSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: KitabColors.warning),
                      const SizedBox(width: KitabSpacing.sm),
                      Flexible(
                        child: Text(
                          'Prayer times will use approximate defaults. Day/Night display will be hidden.',
                          style: KitabTypography.bodySmall.copyWith(color: KitabColors.warning),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (mode == 'manual') {
                return _ManualLocationPicker(settings: settings);
              }

              // GPS mode
              final locationAsync = ref.watch(userLocationProvider);
              return locationAsync.when(
                data: (location) {
                  if (location != null) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, size: 20, color: KitabColors.success),
                      title: FutureBuilder<String>(
                        future: GeocodingService.reverseGeocodeCity(location.latitude, location.longitude),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) return Text(snapshot.data!);
                          return const Text('Location active');
                        },
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final service = ref.read(locationServiceProvider);
                          await service.getLocation(forceRefresh: true);
                          ref.invalidate(userLocationProvider);
                        },
                        child: const Text('Refresh'),
                      ),
                    );
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_off, size: 20, color: KitabColors.warning),
                    title: const Text('Could not get location'),
                    subtitle: const Text('Check browser/device location permissions'),
                  );
                },
                loading: () => const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  title: Text('Getting location...'),
                ),
                error: (e, st) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.error_outline, size: 20, color: KitabColors.error),
                  title: const Text('Location error'),
                  subtitle: Text('$e', style: KitabTypography.caption),
                ),
              );
            }),
          ],

          const Divider(),
          const SizedBox(height: KitabSpacing.md),
          Text('Date & Time', style: KitabTypography.h3),
          const SizedBox(height: KitabSpacing.sm),

          DropdownButtonFormField<String>(
            value: settings.dateFormat,
            decoration: const InputDecoration(labelText: 'Date Format'),
            items: const [
              DropdownMenuItem(value: 'written_short', child: Text('Apr 6, 2026')),
              DropdownMenuItem(value: 'written_long', child: Text('April 6, 2026')),
              DropdownMenuItem(value: 'MM/DD/YYYY', child: Text('04/06/2026')),
              DropdownMenuItem(value: 'DD/MM/YYYY', child: Text('06/04/2026')),
              DropdownMenuItem(value: 'YYYY-MM-DD', child: Text('2026-04-06')),
            ],
            onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'date_format': v}),
          ),
          const SizedBox(height: KitabSpacing.md),

          DropdownButtonFormField<String>(
            value: settings.timeFormat,
            decoration: const InputDecoration(labelText: 'Time Format'),
            items: const [
              DropdownMenuItem(value: '12hr', child: Text('12-hour (3:00 PM)')),
              DropdownMenuItem(value: '24hr', child: Text('24-hour (15:00)')),
            ],
            onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'time_format': v}),
          ),
          const SizedBox(height: KitabSpacing.md),

          DropdownButtonFormField<int>(
            value: settings.weekStartDay,
            decoration: const InputDecoration(labelText: 'Week Starts On'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Sunday')),
              DropdownMenuItem(value: 1, child: Text('Monday')),
              DropdownMenuItem(value: 2, child: Text('Tuesday')),
              DropdownMenuItem(value: 3, child: Text('Wednesday')),
              DropdownMenuItem(value: 4, child: Text('Thursday')),
              DropdownMenuItem(value: 5, child: Text('Friday')),
              DropdownMenuItem(value: 6, child: Text('Saturday')),
            ],
            onChanged: (v) => ref.read(userSettingsProvider.notifier).update({'week_start_day': v}),
          ),
        ],
      ),
    );
  }
}

/// Manual location picker — search for a city and save its coordinates.
class _ManualLocationPicker extends ConsumerStatefulWidget {
  final UserSettings settings;
  const _ManualLocationPicker({required this.settings});

  @override
  ConsumerState<_ManualLocationPicker> createState() => _ManualLocationPickerState();
}

class _ManualLocationPickerState extends ConsumerState<_ManualLocationPicker> {
  final _controller = TextEditingController();
  List<LocationResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await GeocodingService.searchPlace(query);
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedName = widget.settings.manualLocationName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: KitabSpacing.sm),

        // Current selection
        if (savedName != null && savedName.isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on, size: 20, color: KitabColors.success),
            title: Text(savedName),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => setState(() {}), // Just show the search
            ),
          ),

        // Search field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Search for a city',
            hintText: 'e.g. Dubai, Mecca, London...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          onChanged: _search,
        ),

        // Search results
        if (_results.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: KitabRadii.borderSm,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              itemBuilder: (_, index) {
                final result = _results[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place, size: 18, color: KitabColors.gray400),
                  title: Text(result.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    // Get the friendly city name for this location
                    final cityName = await GeocodingService.reverseGeocodeCity(
                      result.latitude, result.longitude,
                    );
                    ref.read(userSettingsProvider.notifier).update({
                      'manual_latitude': result.latitude,
                      'manual_longitude': result.longitude,
                      'manual_location_name': cityName,
                    });
                    ref.invalidate(userLocationProvider);
                    _controller.clear();
                    setState(() => _results = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

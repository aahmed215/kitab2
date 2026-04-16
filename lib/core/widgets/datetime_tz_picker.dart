// ═══════════════════════════════════════════════════════════════════
// DATETIME_TZ_PICKER.DART — Date + Time + Timezone Picker
// Shows a ListTile that opens date picker → time picker → timezone.
// Displays full datetime with timezone offset.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';
import '../utils/date_formatter.dart';

/// A datetime value with an explicit UTC offset.
class DateTimeTz {
  final DateTime dateTime;
  final Duration utcOffset;
  final String tzLabel; // e.g., "EST", "UTC+5", etc.

  DateTimeTz({
    required this.dateTime,
    Duration? utcOffset,
    String? tzLabel,
  })  : utcOffset = utcOffset ?? DateTime.now().timeZoneOffset,
        tzLabel = tzLabel ?? DateTime.now().timeZoneName;

  /// Create from the current local time.
  factory DateTimeTz.now() => DateTimeTz(dateTime: DateTime.now());

  /// Formatted display string.
  /// Uses [fmt] if provided, otherwise falls back to default formatting.
  String formattedWith(KitabDateFormat fmt) =>
      '${fmt.fullDateWithTime(dateTime)} ($tzLabel)';

  /// Formatted display string (default formatting for contexts without settings).
  String get formatted =>
      formattedWith(const KitabDateFormat());

  /// Short format (time only + tz).
  /// Uses [fmt] if provided, otherwise falls back to default formatting.
  String shortFormattedWith(KitabDateFormat fmt) =>
      '${fmt.time(dateTime)} ($tzLabel)';

  /// Short format (time only + tz, default formatting).
  String get shortFormatted =>
      shortFormattedWith(const KitabDateFormat());
}

/// Common UTC offsets for the timezone picker.
final _commonOffsets = [
  (offset: const Duration(hours: -12), label: 'UTC-12 (Baker Island)'),
  (offset: const Duration(hours: -11), label: 'UTC-11 (Samoa)'),
  (offset: const Duration(hours: -10), label: 'UTC-10 (Hawaii)'),
  (offset: const Duration(hours: -9), label: 'UTC-9 (Alaska)'),
  (offset: const Duration(hours: -8), label: 'UTC-8 (Pacific)'),
  (offset: const Duration(hours: -7), label: 'UTC-7 (Mountain)'),
  (offset: const Duration(hours: -6), label: 'UTC-6 (Central)'),
  (offset: const Duration(hours: -5), label: 'UTC-5 (Eastern)'),
  (offset: const Duration(hours: -4), label: 'UTC-4 (Atlantic)'),
  (offset: const Duration(hours: -3), label: 'UTC-3 (Buenos Aires)'),
  (offset: const Duration(hours: -2), label: 'UTC-2'),
  (offset: const Duration(hours: -1), label: 'UTC-1 (Azores)'),
  (offset: Duration.zero, label: 'UTC+0 (London/GMT)'),
  (offset: const Duration(hours: 1), label: 'UTC+1 (Paris/Berlin)'),
  (offset: const Duration(hours: 2), label: 'UTC+2 (Cairo/Athens)'),
  (offset: const Duration(hours: 3), label: 'UTC+3 (Riyadh/Moscow)'),
  (offset: const Duration(hours: 3, minutes: 30), label: 'UTC+3:30 (Tehran)'),
  (offset: const Duration(hours: 4), label: 'UTC+4 (Dubai)'),
  (offset: const Duration(hours: 4, minutes: 30), label: 'UTC+4:30 (Kabul)'),
  (offset: const Duration(hours: 5), label: 'UTC+5 (Karachi)'),
  (offset: const Duration(hours: 5, minutes: 30), label: 'UTC+5:30 (Mumbai)'),
  (offset: const Duration(hours: 6), label: 'UTC+6 (Dhaka)'),
  (offset: const Duration(hours: 7), label: 'UTC+7 (Bangkok)'),
  (offset: const Duration(hours: 8), label: 'UTC+8 (Singapore/Beijing)'),
  (offset: const Duration(hours: 9), label: 'UTC+9 (Tokyo)'),
  (offset: const Duration(hours: 9, minutes: 30), label: 'UTC+9:30 (Adelaide)'),
  (offset: const Duration(hours: 10), label: 'UTC+10 (Sydney)'),
  (offset: const Duration(hours: 11), label: 'UTC+11'),
  (offset: const Duration(hours: 12), label: 'UTC+12 (Auckland)'),
];

/// A tile that shows a date+time+timezone and opens pickers on tap.
class DateTimeTzTile extends StatelessWidget {
  final String label;
  final DateTimeTz? value;
  final ValueChanged<DateTimeTz> onChanged;
  final IconData icon;

  const DateTimeTzTile({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.icon = Icons.access_time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: KitabColors.gray400),
      title: Text(label),
      subtitle: Text(
        value?.formatted ?? 'Tap to set',
        style: KitabTypography.bodySmall.copyWith(
          color: value != null ? null : KitabColors.gray400,
        ),
      ),
      trailing: const Icon(Icons.edit, size: 16, color: KitabColors.gray400),
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final current = value ?? DateTimeTz.now();

    // Step 1: Date
    final date = await showDatePicker(
      context: context,
      initialDate: current.dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;

    // Step 2: Time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current.dateTime),
    );
    if (time == null || !context.mounted) return;

    final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Step 3: Timezone (optional — show a "Change timezone?" option)
    final newTz = await _pickTimezone(context, current.utcOffset, current.tzLabel);

    onChanged(DateTimeTz(
      dateTime: newDt,
      utcOffset: newTz?.offset ?? current.utcOffset,
      tzLabel: newTz?.label ?? current.tzLabel,
    ));
  }

  Future<({Duration offset, String label})?> _pickTimezone(
      BuildContext context, Duration currentOffset, String currentLabel) async {
    return showModalBottomSheet<({Duration offset, String label})>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(KitabSpacing.md),
            child: Row(
              children: [
                Text('Timezone', style: KitabTypography.h3),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx), // Keep current
                  child: const Text('Keep Current'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _commonOffsets.length,
              itemBuilder: (_, index) {
                final tz = _commonOffsets[index];
                final isSelected = tz.offset == currentOffset;
                return ListTile(
                  title: Text(tz.label),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: KitabColors.primary)
                      : null,
                  selected: isSelected,
                  onTap: () {
                    // Extract short label (e.g., "UTC-5" from "UTC-5 (Eastern)")
                    final shortLabel = tz.label.split(' (').first;
                    Navigator.pop(ctx, (offset: tz.offset, label: shortLabel));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

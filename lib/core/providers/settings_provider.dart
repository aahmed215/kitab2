// ═══════════════════════════════════════════════════════════════════
// SETTINGS_PROVIDER.DART — User Settings State Management
// Reads/writes the `settings` JSONB column in the public.users table.
// Re-loads automatically when auth state changes (sign in/out).
// All settings screens read from and write to this provider.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/date_formatter.dart';
import 'auth_provider.dart';

/// All user settings in a single map. Stored in users.settings JSONB.
class UserSettings {
  final Map<String, dynamic> _data;

  UserSettings(Map<String, dynamic>? data) : _data = data ?? {};

  // ─── Getters with defaults ───

  String get theme => _data['theme'] as String? ?? 'light';

  bool get islamicPersonalization => _data['islamic_personalization'] as bool? ?? false;
  bool get hijriCalendarEnabled => _data['hijri_calendar_enabled'] as bool? ?? false;
  String get hijriMethod => _data['hijri_method'] as String? ?? 'umm_al_qura';
  String get prayerCalculationMethod => _data['prayer_calculation_method'] as String? ?? 'umm_al_qura';
  String get prayerMadhab => _data['prayer_madhab'] as String? ?? 'shafi';

  /// Location mode: 'gps' (automatic), 'manual' (user-selected city), 'off' (no location)
  String get locationMode => _data['location_mode'] as String? ?? 'gps';

  /// Manual location coordinates (used when locationMode == 'manual')
  double? get manualLatitude => (_data['manual_latitude'] as num?)?.toDouble();
  double? get manualLongitude => (_data['manual_longitude'] as num?)?.toDouble();
  String? get manualLocationName => _data['manual_location_name'] as String?;

  String get dateFormat => _data['date_format'] as String? ?? 'written_short';
  String get timeFormat => _data['time_format'] as String? ?? '12hr';
  int get weekStartDay => _data['week_start_day'] as int? ?? 0;

  String get defaultSharing => _data['default_sharing'] as String? ?? 'private';
  String get profileVisibility => _data['profile_visibility'] as String? ?? 'friends_only';
  bool get analyticsEnabled => _data['analytics_enabled'] as bool? ?? true;

  bool get notifyStreakRisk => _data['notify_streak_risk'] as bool? ?? true;
  bool get notifyStreakMilestone => _data['notify_streak_milestone'] as bool? ?? true;
  bool get notifyReminders => _data['notify_reminders'] as bool? ?? true;
  String get reminderTime => _data['reminder_time'] as String? ?? '21:00';
  bool get notifyFriendRequests => _data['notify_friend_requests'] as bool? ?? true;
  bool get notifyCompetitionUpdates => _data['notify_competition_updates'] as bool? ?? true;
  bool get notifyConditionReminders => _data['notify_condition_reminders'] as bool? ?? true;
  int get conditionReminderDays => _data['condition_reminder_days'] as int? ?? 7;

  UserSettings copyWith(Map<String, dynamic> updates) {
    return UserSettings({..._data, ...updates});
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_data);
}

/// Reactive date/time formatter that updates when settings change.
final dateFormatterProvider = Provider<KitabDateFormat>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return KitabDateFormat(
    dateFormat: settings.dateFormat,
    timeFormat: settings.timeFormat,
  );
});

/// Loads settings from Supabase. Re-creates when userId changes
/// (sign in / sign out) so settings are always fresh.
final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  // Watch the auth state — when userId changes, this provider
  // is disposed and re-created, triggering a fresh load.
  final userId = ref.watch(currentUserIdProvider);
  final notifier = UserSettingsNotifier(ref, userId);
  notifier._load();
  return notifier;
});

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final String _userId;

  UserSettingsNotifier(Ref ref, this._userId) : super(UserSettings(null));

  Future<void> _load() async {
    if (_userId == 'local-user') return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('settings')
          .eq('id', _userId)
          .maybeSingle();

      if (response != null && response['settings'] != null) {
        state = UserSettings(Map<String, dynamic>.from(response['settings'] as Map));
      }
    } catch (e) {
      // Keep defaults on error
    }
  }

  /// Update one or more settings and persist to database.
  Future<void> update(Map<String, dynamic> updates) async {
    state = state.copyWith(updates);

    if (_userId == 'local-user') return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'settings': state.toJson(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _userId);
    } catch (e) {
      // Settings saved in memory even if cloud save fails
    }
  }

  /// Force reload from database.
  Future<void> reload() => _load();
}

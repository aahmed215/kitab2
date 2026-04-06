// ═══════════════════════════════════════════════════════════════════
// USER_PROFILE.DART — User Profile Data Model
// Extends Supabase auth.users with app-specific profile data.
// Settings stored as a separate model within JSONB.
// Maps to the `users` table in Supabase.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// The user's profile information and app settings.
/// Linked to Supabase auth.users via the id field.
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Supabase auth user ID (UUID)
    required String id,

    /// Email address (nullable for anonymous users on native)
    String? email,

    /// Unique username for friend search and invite links
    /// Format: 3-20 chars, alphanumeric + underscores, case-insensitive
    String? username,

    /// Display name
    String? name,

    /// Profile photo URL (stored in Supabase Storage)
    String? avatarUrl,

    /// Short bio (max 150 chars)
    String? bio,

    /// Birthday (used for birthday greeting)
    DateTime? birthday,

    /// Preferred timezone identifier (e.g., "America/New_York")
    String? timezone,

    /// Last time username was changed (30-day cooldown enforced)
    DateTime? usernameChangedAt,

    /// App settings stored as JSONB — see UserSettings model
    @Default({}) Map<String, dynamic> settings,

    /// When the profile was created
    required DateTime createdAt,

    /// When the profile was last updated
    required DateTime updatedAt,

    /// Soft delete timestamp
    DateTime? deletedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

/// User app settings — stored inside users.settings JSONB column.
/// Extracted as a separate model for type-safe access.
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    // ─── Theme ───
    /// 'light', 'dark', or 'system'
    @Default('system') String theme,

    // ─── Islamic Personalization ───
    /// Whether Islamic greetings, Hijri dates, prayer times are enabled
    @Default(false) bool islamicPersonalization,

    /// Whether the Hijri calendar is shown
    @Default(false) bool hijriCalendarEnabled,

    /// Hijri calculation method (e.g., 'umm_al_qura', 'astronomical')
    @Default('umm_al_qura') String hijriMethod,

    /// Manual Hijri date adjustment (-2 to +2 days)
    @Default(0) int hijriDayAdjustment,

    /// When the Hijri day advances: 'sunset' or 'midnight'
    @Default('sunset') String hijriDayAdvancement,

    // ─── Prayer Times ───
    /// Prayer calculation method (e.g., 'isna', 'mwl', 'egyptian')
    @Default('isna') String prayerCalculationMethod,

    /// Madhab for Asr calculation: 'shafi' or 'hanafi'
    @Default('shafi') String prayerMadhab,

    /// High latitude adjustment: 'middle_of_night', 'one_seventh', 'angle_based'
    String? highLatitudeMethod,

    // ─── Date & Time Format ───
    /// Date format: 'MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD', 'written_short', 'written_long'
    @Default('written_short') String dateFormat,

    /// Time format: '12hr' or '24hr'
    @Default('12hr') String timeFormat,

    /// Timezone display: 'abbreviation' or 'utc_offset'
    @Default('abbreviation') String timezoneDisplay,

    /// Default timezone: 'auto' or a specific timezone ID
    @Default('auto') String defaultTimezone,

    /// Week start day: 0 = Sunday, 1 = Monday, 6 = Saturday
    @Default(0) int weekStartDay,

    // ─── Privacy ───
    /// Default sharing for new activities: 'private', 'friends', 'all_friends'
    @Default('private') String defaultSharing,

    /// Profile visibility: 'friends_only', 'anyone', 'nobody'
    @Default('friends_only') String profileVisibility,

    /// Whether analytics tracking is enabled (opt-out toggle)
    @Default(true) bool analyticsEnabled,

    // ─── Notifications ───
    /// Whether streak-at-risk notifications are enabled
    @Default(true) bool notifyStreakRisk,

    /// Whether streak milestone notifications are enabled
    @Default(true) bool notifyStreakMilestone,

    /// Whether reminder notifications are enabled
    @Default(true) bool notifyReminders,

    /// Reminder time in 24hr format (e.g., '21:00' for 9 PM)
    @Default('21:00') String reminderTime,

    /// Whether friend request notifications are enabled
    @Default(true) bool notifyFriendRequests,

    /// Whether competition update notifications are enabled
    @Default(true) bool notifyCompetitionUpdates,

    /// Whether condition reminder notifications are enabled
    @Default(true) bool notifyConditionReminders,

    /// Condition reminder interval in days
    @Default(7) int conditionReminderDays,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

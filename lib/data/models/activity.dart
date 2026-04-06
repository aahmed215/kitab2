// ═══════════════════════════════════════════════════════════════════
// ACTIVITY.DART — Activity Template Data Model
// The foundational data structure of Kitab.
// Contains schedule (versioned), fields, and goals (versioned).
// Maps to the `activities` table in Supabase.
// See SPEC.md §5 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

/// An activity template — the configuration that defines what a user tracks,
/// how often, and what goals they want to achieve.
@freezed
class Activity with _$Activity {
  const factory Activity({
    /// Unique identifier (UUID)
    required String id,

    /// Owner's user ID
    required String userId,

    /// Category this activity belongs to (provides icon + color)
    required String categoryId,

    /// Activity name — unique per user (case-insensitive)
    required String name,

    /// Optional description
    String? description,

    /// Whether this activity is archived (hidden from active lists)
    @Default(false) bool isArchived,

    /// Whether this activity's name/details are blurred for privacy
    @Default(false) bool isPrivate,

    /// Schedule configuration (versioned JSONB)
    /// null = no schedule (log whenever)
    Map<String, dynamic>? schedule,

    /// Array of field definitions (JSONB)
    /// Each field: { id, type, label, unit, config, sort_order }
    @Default([]) List<Map<String, dynamic>> fields,

    /// Goal configuration (versioned JSONB)
    /// null = no goals
    Map<String, dynamic>? goals,

    /// Which goal ID (inside goals JSONB) is the primary goal
    String? primaryGoalId,

    /// When this template was created
    required DateTime createdAt,

    /// When this template was last updated
    required DateTime updatedAt,

    /// Soft delete timestamp
    DateTime? deletedAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}

// ═══════════════════════════════════════════════════════════════════
// JSONB SUB-MODELS
// These define the structure of the JSONB columns.
// ═══════════════════════════════════════════════════════════════════

/// A single version of a schedule configuration.
/// Schedule is versioned: when the user changes it, a new version is appended.
/// "Future only" = new version. "Retroactive" = collapse to single version.
@freezed
class ScheduleVersion with _$ScheduleVersion {
  const factory ScheduleVersion({
    /// When this version became effective
    required String effectiveFrom,

    /// When this version was superseded (null = current)
    String? effectiveTo,

    /// The schedule configuration for this version
    required ScheduleConfig config,
  }) = _ScheduleVersion;

  factory ScheduleVersion.fromJson(Map<String, dynamic> json) =>
      _$ScheduleVersionFromJson(json);
}

/// The actual schedule configuration.
@freezed
class ScheduleConfig with _$ScheduleConfig {
  const factory ScheduleConfig({
    /// 'gregorian' or 'hijri'
    required String calendarType,

    /// When the schedule starts (ISO date string)
    required String startDate,

    /// When the schedule ends (null = never)
    String? endDate,

    /// Repeat type: 'daily', 'weekly', 'monthly', 'yearly', 'custom'
    required String repeatType,

    /// Repeat-specific configuration
    /// Weekly: { days: [0,1,3] } (0=Sun, 6=Sat)
    /// Monthly: { days: [13,14,15], asOnePeriod: true }
    /// Yearly: { month: 'Ramadan', days: [1,2,...,30] }
    /// Custom: { interval: 2, unit: 'weeks' }
    Map<String, dynamic>? repeatConfig,

    /// 'once' or 'multiple' per period
    @Default('once') String expectedEntries,

    /// Time window configuration (null = full day)
    TimeWindowConfig? timeWindow,
  }) = _ScheduleConfig;

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) =>
      _$ScheduleConfigFromJson(json);
}

/// Time window within a period (specific or dynamic times).
@freezed
class TimeWindowConfig with _$TimeWindowConfig {
  const factory TimeWindowConfig({
    /// 'specific' or 'dynamic'
    required String timeType,

    /// Start time value — clock time (HH:MM) or dynamic reference ('fajr', 'sunrise', etc.)
    required String windowStart,

    /// Offset in minutes added to dynamic start time (e.g., +15 for Duha)
    @Default(0) int windowStartOffset,

    /// End time value
    required String windowEnd,

    /// Offset in minutes added to dynamic end time
    @Default(0) int windowEndOffset,
  }) = _TimeWindowConfig;

  factory TimeWindowConfig.fromJson(Map<String, dynamic> json) =>
      _$TimeWindowConfigFromJson(json);
}

/// A single field definition within an activity template.
@freezed
class FieldDefinition with _$FieldDefinition {
  const factory FieldDefinition({
    /// Unique ID for this field (UUID string)
    required String id,

    /// Field type: 'start_time', 'end_time', 'duration', 'number', 'text',
    /// 'star_rating', 'mood', 'yes_no', 'single_choice', 'multiple_choice',
    /// 'range', 'location', 'list'
    required String type,

    /// User-facing label (e.g., "Distance", "Pages Read")
    required String label,

    /// Optional unit (e.g., "km", "pages", "glasses")
    String? unit,

    /// Type-specific configuration
    /// Range: { min: 0, max: 100, step: 1 }
    /// Single/Multiple Choice: { options: ["Good", "Fair", "Poor"], ordinal: true }
    Map<String, dynamic>? config,

    /// Display order within the entry form
    @Default(0) int sortOrder,

    /// Whether this is a preset field (Start Time, End Time, Duration)
    @Default(false) bool isPreset,
  }) = _FieldDefinition;

  factory FieldDefinition.fromJson(Map<String, dynamic> json) =>
      _$FieldDefinitionFromJson(json);
}

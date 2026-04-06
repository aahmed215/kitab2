// ═══════════════════════════════════════════════════════════════════
// CONDITION.DART — Condition Data Models
// ConditionPreset: reusable condition types (Sick, Traveling, etc.)
// Condition: actual instance with start/end dates.
// Maps to `condition_presets` and `conditions` tables.
// See SPEC.md §2.1 Conditions for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'condition.freezed.dart';
part 'condition.g.dart';

/// A reusable condition type (e.g., Sick, Traveling, Injured).
/// System presets can be hidden but not deleted.
/// User-created presets are fully editable.
@freezed
class ConditionPreset with _$ConditionPreset {
  const factory ConditionPreset({
    required String id,
    required String userId,

    /// Display label — unique per user (case-insensitive)
    required String label,

    /// Emoji icon
    required String emoji,

    /// Whether this is a system-provided preset (can't be deleted, can be hidden)
    @Default(false) bool isSystem,

    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _ConditionPreset;

  factory ConditionPreset.fromJson(Map<String, dynamic> json) =>
      _$ConditionPresetFromJson(json);
}

/// An actual condition instance — a life event with start/end dates.
/// Day-level granularity (not time-level).
/// Non-overlapping per preset type.
@freezed
class Condition with _$Condition {
  const factory Condition({
    required String id,
    required String userId,

    /// Which preset this condition is based on
    required String presetId,

    /// Display label (inherited from preset at creation)
    required String label,

    /// Emoji (inherited from preset at creation)
    required String emoji,

    /// Start date of the condition (day-level)
    required DateTime startDate,

    /// End date (null = active/ongoing)
    DateTime? endDate,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Condition;

  factory Condition.fromJson(Map<String, dynamic> json) =>
      _$ConditionFromJson(json);
}

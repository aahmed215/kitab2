// ═══════════════════════════════════════════════════════════════════
// PERIOD_STATUS.DART — Period & Goal Status Models
// Tracks the status of each scheduled period and its goals.
// 'completed'/'pending' = system-computed.
// 'missed'/'excused' = user decisions (preserved during sync).
// Maps to activity_period_statuses and goal_period_statuses tables.
// See SPEC.md §12.1 for full schema.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_status.freezed.dart';
part 'period_status.g.dart';

/// Status of a single period for a scheduled activity.
/// Answers: "Did the user do this activity in this period?"
@freezed
class ActivityPeriodStatus with _$ActivityPeriodStatus {
  const factory ActivityPeriodStatus({
    required String id,
    required String userId,
    required String activityId,

    /// Frozen period boundaries (UTC)
    required DateTime periodStart,
    required DateTime periodEnd,

    /// Period status: 'completed', 'missed', 'excused', 'pending'
    /// 'completed'/'pending' = system-computed from entry data
    /// 'missed'/'excused' = user decisions (preserved during sync merge)
    required String status,

    /// Linked condition (when status = 'excused')
    String? conditionId,

    /// When the user addressed this period
    DateTime? resolvedAt,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ActivityPeriodStatus;

  factory ActivityPeriodStatus.fromJson(Map<String, dynamic> json) =>
      _$ActivityPeriodStatusFromJson(json);
}

/// Status of a specific goal within a completed period.
/// Only created when the period status = 'completed' (entry exists).
/// If period is excused/missed, goals inherit that status — no rows created.
@freezed
class GoalPeriodStatus with _$GoalPeriodStatus {
  const factory GoalPeriodStatus({
    required String id,
    required String userId,
    required String activityId,

    /// Matches a goal ID inside the activity's goals JSONB
    required String goalId,

    /// Frozen period boundaries
    required DateTime periodStart,
    required DateTime periodEnd,

    /// Goal status: 'met', 'not_met', 'excused'
    /// 'met'/'not_met' = system-computed by goal engine
    /// 'excused' = user decision with reason
    required String status,

    /// Linked condition (when status = 'excused')
    String? conditionId,

    /// Free-text reason (for one-off reasons not tied to a condition)
    String? reasonText,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _GoalPeriodStatus;

  factory GoalPeriodStatus.fromJson(Map<String, dynamic> json) =>
      _$GoalPeriodStatusFromJson(json);
}

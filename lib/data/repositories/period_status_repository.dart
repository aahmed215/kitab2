// ═══════════════════════════════════════════════════════════════════
// PERIOD_STATUS_REPOSITORY.DART — Abstract interface for
// activity and goal period status tracking.
// ═══════════════════════════════════════════════════════════════════

import '../models/period_status.dart';

/// Contract for period status data access.
abstract class PeriodStatusRepository {
  // ─── Activity Period Statuses ───

  /// Get the status for a specific activity period.
  Future<ActivityPeriodStatus?> getActivityPeriodStatus(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  );

  /// Get all activity period statuses for a date range.
  Future<List<ActivityPeriodStatus>> getActivityStatusesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Get all statuses for a specific activity (for streaks).
  Future<List<ActivityPeriodStatus>> getActivityStatusHistory(
    String userId,
    String activityId,
  );

  /// Save an activity period status.
  Future<void> saveActivityStatus(ActivityPeriodStatus status);

  // ─── Goal Period Statuses ───

  /// Get the status for a specific goal period.
  Future<GoalPeriodStatus?> getGoalPeriodStatus(
    String userId,
    String activityId,
    String goalId,
    DateTime periodStart,
    DateTime periodEnd,
  );

  /// Get all statuses for a specific goal (for streaks).
  Future<List<GoalPeriodStatus>> getGoalStatusHistory(
    String userId,
    String activityId,
    String goalId,
  );

  /// Save a goal period status.
  Future<void> saveGoalStatus(GoalPeriodStatus status);

  // ─── Bulk Operations ───

  /// Delete all activity period statuses for an activity.
  Future<void> deleteAllForActivity(String userId, String activityId);

  /// Delete all goal period statuses for an activity.
  Future<void> deleteAllGoalStatusesForActivity(String userId, String activityId);

  /// Reset all excused statuses linked to a condition back to pending.
  Future<void> clearExcusesByConditionId(String conditionId);

  /// Reset excused statuses for a condition where the period day
  /// falls outside the given date range (for condition date edits).
  Future<void> clearExcusesOutsideRange(String conditionId, DateTime start, DateTime end);
}

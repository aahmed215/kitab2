// ═══════════════════════════════════════════════════════════════════
// PERIOD_STATUSES_DAO.DART — CRUD for activity & goal period statuses
// These track whether a scheduled period was completed, missed, etc.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'period_statuses_dao.g.dart';

@DriftAccessor(tables: [ActivityPeriodStatusesTable, GoalPeriodStatusesTable])
class PeriodStatusesDao extends DatabaseAccessor<KitabDatabase>
    with _$PeriodStatusesDaoMixin {
  PeriodStatusesDao(super.db);

  // ─── Activity Period Statuses ───

  /// Get the status for a specific activity period.
  Future<ActivityPeriodStatusesTableData?> getActivityPeriodStatus(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return (select(activityPeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.activityId.equals(activityId) &
              s.periodStart.equals(periodStart) &
              s.periodEnd.equals(periodEnd) &
              s.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get all activity period statuses for a date range.
  /// Used by home screen to show today's statuses.
  Future<List<ActivityPeriodStatusesTableData>> getActivityStatusesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(activityPeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.deletedAt.isNull() &
              s.periodStart.isBiggerOrEqualValue(start) &
              s.periodStart.isSmallerThanValue(end)))
        .get();
  }

  /// Get all statuses for a specific activity (for streak calculation).
  Future<List<ActivityPeriodStatusesTableData>> getActivityStatusHistory(
    String userId,
    String activityId,
  ) {
    return (select(activityPeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.activityId.equals(activityId) &
              s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.periodStart)]))
        .get();
  }

  /// Insert or replace an activity period status.
  Future<void> upsertActivityStatus(
      ActivityPeriodStatusesTableCompanion status) {
    return into(activityPeriodStatusesTable).insertOnConflictUpdate(status);
  }

  // ─── Goal Period Statuses ───

  /// Get the status for a specific goal period.
  Future<GoalPeriodStatusesTableData?> getGoalPeriodStatus(
    String userId,
    String activityId,
    String goalId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return (select(goalPeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.activityId.equals(activityId) &
              s.goalId.equals(goalId) &
              s.periodStart.equals(periodStart) &
              s.periodEnd.equals(periodEnd) &
              s.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get all goal statuses for a specific activity (for streak calculation).
  Future<List<GoalPeriodStatusesTableData>> getGoalStatusHistory(
    String userId,
    String activityId,
    String goalId,
  ) {
    return (select(goalPeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.activityId.equals(activityId) &
              s.goalId.equals(goalId) &
              s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.periodStart)]))
        .get();
  }

  /// Insert or replace a goal period status.
  Future<void> upsertGoalStatus(GoalPeriodStatusesTableCompanion status) {
    return into(goalPeriodStatusesTable).insertOnConflictUpdate(status);
  }
}

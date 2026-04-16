// ═══════════════════════════════════════════════════════════════════
// DRIFT_PERIOD_STATUS_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/period_status.dart' as domain;
import '../repositories/period_status_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftPeriodStatusRepository implements PeriodStatusRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftPeriodStatusRepository(this._db);

  // ─── Activity Period Statuses ───

  @override
  Future<domain.ActivityPeriodStatus?> getActivityPeriodStatus(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final row = await _db.periodStatusesDao
        .getActivityPeriodStatus(userId, activityId, periodStart, periodEnd);
    return row?.toDomain();
  }

  @override
  Future<List<domain.ActivityPeriodStatus>> getActivityStatusesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await _db.periodStatusesDao.getActivityStatusesByDateRange(userId, start, end);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.ActivityPeriodStatus>> getActivityStatusHistory(
    String userId,
    String activityId,
  ) async {
    final rows =
        await _db.periodStatusesDao.getActivityStatusHistory(userId, activityId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> saveActivityStatus(domain.ActivityPeriodStatus status) async {
    final now = DateTime.now();
    final toSave = status.copyWith(
      id: status.id.isEmpty ? _uuid.v4() : status.id,
      updatedAt: now,
    );
    await _db.periodStatusesDao.upsertActivityStatus(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('activity_period_statuses'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));
  }

  // ─── Goal Period Statuses ───

  @override
  Future<domain.GoalPeriodStatus?> getGoalPeriodStatus(
    String userId,
    String activityId,
    String goalId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final row = await _db.periodStatusesDao
        .getGoalPeriodStatus(userId, activityId, goalId, periodStart, periodEnd);
    return row?.toDomain();
  }

  @override
  Future<List<domain.GoalPeriodStatus>> getGoalStatusHistory(
    String userId,
    String activityId,
    String goalId,
  ) async {
    final rows = await _db.periodStatusesDao
        .getGoalStatusHistory(userId, activityId, goalId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<void> saveGoalStatus(domain.GoalPeriodStatus status) async {
    final now = DateTime.now();
    final toSave = status.copyWith(
      id: status.id.isEmpty ? _uuid.v4() : status.id,
      updatedAt: now,
    );
    await _db.periodStatusesDao.upsertGoalStatus(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('goal_period_statuses'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));
  }

  // ─── Bulk Operations (TODO: implement with Drift queries) ───

  @override
  Future<void> deleteAllForActivity(String userId, String activityId) async {
    // TODO: Implement with Drift
  }

  @override
  Future<void> deleteAllGoalStatusesForActivity(String userId, String activityId) async {
    // TODO: Implement with Drift
  }

  @override
  Future<void> clearExcusesByConditionId(String conditionId) async {
    // TODO: Implement with Drift
  }

  @override
  Future<void> clearExcusesOutsideRange(String conditionId, DateTime start, DateTime end) async {
    // TODO: Implement with Drift
  }
}

// ═══════════════════════════════════════════════════════════════════
// ROUTINES_DAO.DART — CRUD for routines, routine entries, and
// routine period/goal statuses.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'routines_dao.g.dart';

@DriftAccessor(tables: [
  RoutinesTable,
  RoutineEntriesTable,
  RoutinePeriodStatusesTable,
  RoutineGoalPeriodStatusesTable,
])
class RoutinesDao extends DatabaseAccessor<KitabDatabase>
    with _$RoutinesDaoMixin {
  RoutinesDao(super.db);

  // ─── Routine Templates ───

  /// Watch all non-deleted, non-archived routines for a user.
  Stream<List<RoutinesTableData>> watchActiveByUser(String userId) {
    return (select(routinesTable)
          ..where((r) =>
              r.userId.equals(userId) &
              r.deletedAt.isNull() &
              r.isArchived.equals(false)))
        .watch();
  }

  /// Get all non-deleted routines for a user.
  Future<List<RoutinesTableData>> getByUser(String userId) {
    return (select(routinesTable)
          ..where((r) => r.userId.equals(userId) & r.deletedAt.isNull()))
        .get();
  }

  /// Get a single routine by ID.
  Future<RoutinesTableData?> getById(String id) {
    return (select(routinesTable)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a routine.
  Future<void> upsert(RoutinesTableCompanion routine) {
    return into(routinesTable).insertOnConflictUpdate(routine);
  }

  /// Soft-delete a routine.
  Future<void> softDelete(String id) {
    return (update(routinesTable)..where((r) => r.id.equals(id)))
        .write(RoutinesTableCompanion(deletedAt: Value(DateTime.now())));
  }

  // ─── Routine Entries (Sessions) ───

  /// Get routine entries for a date range.
  Future<List<RoutineEntriesTableData>> getEntriesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(routineEntriesTable)
          ..where((e) =>
              e.userId.equals(userId) &
              e.deletedAt.isNull() &
              e.createdAt.isBiggerOrEqualValue(start) &
              e.createdAt.isSmallerThanValue(end))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  /// Get a single routine entry by ID.
  Future<RoutineEntriesTableData?> getEntryById(String id) {
    return (select(routineEntriesTable)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a routine entry.
  Future<void> upsertEntry(RoutineEntriesTableCompanion entry) {
    return into(routineEntriesTable).insertOnConflictUpdate(entry);
  }

  // ─── Routine Period Statuses ───

  /// Get the status for a specific routine period.
  Future<RoutinePeriodStatusesTableData?> getPeriodStatus(
    String userId,
    String routineId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return (select(routinePeriodStatusesTable)
          ..where((s) =>
              s.userId.equals(userId) &
              s.routineId.equals(routineId) &
              s.periodStart.equals(periodStart) &
              s.periodEnd.equals(periodEnd) &
              s.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Insert or replace a routine period status.
  Future<void> upsertPeriodStatus(
      RoutinePeriodStatusesTableCompanion status) {
    return into(routinePeriodStatusesTable).insertOnConflictUpdate(status);
  }

  // ─── Routine Goal Period Statuses ───

  /// Insert or replace a routine goal period status.
  Future<void> upsertGoalStatus(
      RoutineGoalPeriodStatusesTableCompanion status) {
    return into(routineGoalPeriodStatusesTable).insertOnConflictUpdate(status);
  }
}

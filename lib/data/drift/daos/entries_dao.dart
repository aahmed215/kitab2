// ═══════════════════════════════════════════════════════════════════
// ENTRIES_DAO.DART — CRUD operations for activity entries (logs)
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'entries_dao.g.dart';

@DriftAccessor(tables: [EntriesTable])
class EntriesDao extends DatabaseAccessor<KitabDatabase>
    with _$EntriesDaoMixin {
  EntriesDao(super.db);

  /// Watch all non-deleted entries for a user, newest first.
  Stream<List<EntriesTableData>> watchByUser(String userId) {
    return (select(entriesTable)
          ..where((e) => e.userId.equals(userId) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.desc(e.loggedAt)]))
        .watch();
  }

  /// Get entries for a specific activity within a date range.
  /// Used by the goal engine to evaluate period completion.
  Future<List<EntriesTableData>> getByActivityAndPeriod(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return (select(entriesTable)
          ..where((e) =>
              e.userId.equals(userId) &
              e.activityId.equals(activityId) &
              e.deletedAt.isNull() &
              e.loggedAt.isBiggerOrEqualValue(periodStart) &
              e.loggedAt.isSmallerThanValue(periodEnd)))
        .get();
  }

  /// Get entries linked to a specific period (Layer 2 linkage).
  Future<List<EntriesTableData>> getByPeriod(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return (select(entriesTable)
          ..where((e) =>
              e.userId.equals(userId) &
              e.activityId.equals(activityId) &
              e.deletedAt.isNull() &
              e.periodStart.equals(periodStart) &
              e.periodEnd.equals(periodEnd)))
        .get();
  }

  /// Get entries for a date range (for home screen "today" view).
  Future<List<EntriesTableData>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(entriesTable)
          ..where((e) =>
              e.userId.equals(userId) &
              e.deletedAt.isNull() &
              e.loggedAt.isBiggerOrEqualValue(start) &
              e.loggedAt.isSmallerThanValue(end))
          ..orderBy([(e) => OrderingTerm.desc(e.loggedAt)]))
        .get();
  }

  /// Get entries linked to a routine entry.
  Future<List<EntriesTableData>> getByRoutineEntry(String routineEntryId) {
    return (select(entriesTable)
          ..where((e) =>
              e.routineEntryId.equals(routineEntryId) & e.deletedAt.isNull()))
        .get();
  }

  /// Get a single entry by ID.
  Future<EntriesTableData?> getById(String id) {
    return (select(entriesTable)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace an entry (used by sync).
  Future<void> upsert(EntriesTableCompanion entry) {
    return into(entriesTable).insertOnConflictUpdate(entry);
  }

  /// Soft-delete an entry.
  Future<void> softDelete(String id) {
    return (update(entriesTable)..where((e) => e.id.equals(id)))
        .write(EntriesTableCompanion(deletedAt: Value(DateTime.now())));
  }

  /// Get all entries modified after a given timestamp (for sync pull).
  Future<List<EntriesTableData>> getModifiedAfter(
      String userId, DateTime after) {
    return (select(entriesTable)
          ..where(
              (e) => e.userId.equals(userId) & e.updatedAt.isBiggerThanValue(after)))
        .get();
  }
}

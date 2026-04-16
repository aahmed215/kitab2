// ═══════════════════════════════════════════════════════════════════
// ACTIVITIES_DAO.DART — CRUD operations for activity templates
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'activities_dao.g.dart';

@DriftAccessor(tables: [ActivitiesTable])
class ActivitiesDao extends DatabaseAccessor<KitabDatabase>
    with _$ActivitiesDaoMixin {
  ActivitiesDao(super.db);

  /// Watch all non-deleted, non-archived activities for a user.
  Stream<List<ActivitiesTableData>> watchActiveByUser(String userId) {
    return (select(activitiesTable)
          ..where((a) =>
              a.userId.equals(userId) &
              a.deletedAt.isNull() &
              a.isArchived.equals(false)))
        .watch();
  }

  /// Get all non-deleted activities for a user (including archived).
  Future<List<ActivitiesTableData>> getByUser(String userId) {
    return (select(activitiesTable)
          ..where((a) => a.userId.equals(userId) & a.deletedAt.isNull()))
        .get();
  }

  /// Get activities in a specific category.
  Future<List<ActivitiesTableData>> getByCategory(
      String userId, String categoryId) {
    return (select(activitiesTable)
          ..where((a) =>
              a.userId.equals(userId) &
              a.categoryId.equals(categoryId) &
              a.deletedAt.isNull()))
        .get();
  }

  /// Get a single activity by ID.
  Future<ActivitiesTableData?> getById(String id) {
    return (select(activitiesTable)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace an activity (used by sync).
  Future<void> upsert(ActivitiesTableCompanion activity) {
    return into(activitiesTable).insertOnConflictUpdate(activity);
  }

  /// Soft-delete an activity.
  Future<void> softDelete(String id) {
    return (update(activitiesTable)..where((a) => a.id.equals(id)))
        .write(ActivitiesTableCompanion(deletedAt: Value(DateTime.now())));
  }

  /// Get all activities modified after a given timestamp (for sync pull).
  Future<List<ActivitiesTableData>> getModifiedAfter(
      String userId, DateTime after) {
    return (select(activitiesTable)
          ..where(
              (a) => a.userId.equals(userId) & a.updatedAt.isBiggerThanValue(after)))
        .get();
  }
}

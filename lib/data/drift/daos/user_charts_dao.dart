// ═══════════════════════════════════════════════════════════════════
// USER_CHARTS_DAO.DART — CRUD for custom chart configurations
// Used by the Insights screen's "My Charts" tab.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'user_charts_dao.g.dart';

@DriftAccessor(tables: [UserChartsTable])
class UserChartsDao extends DatabaseAccessor<KitabDatabase>
    with _$UserChartsDaoMixin {
  UserChartsDao(super.db);

  /// Watch all non-deleted charts for a user, ordered by sort_order.
  Stream<List<UserChartsTableData>> watchByUser(String userId) {
    return (select(userChartsTable)
          ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Watch favorite charts only.
  Stream<List<UserChartsTableData>> watchFavorites(String userId) {
    return (select(userChartsTable)
          ..where((c) =>
              c.userId.equals(userId) &
              c.deletedAt.isNull() &
              c.isFavorite.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get a single chart by ID.
  Future<UserChartsTableData?> getById(String id) {
    return (select(userChartsTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a chart.
  Future<void> upsert(UserChartsTableCompanion chart) {
    return into(userChartsTable).insertOnConflictUpdate(chart);
  }

  /// Soft-delete a chart.
  Future<void> softDelete(String id) {
    return (update(userChartsTable)..where((c) => c.id.equals(id)))
        .write(UserChartsTableCompanion(deletedAt: Value(DateTime.now())));
  }
}

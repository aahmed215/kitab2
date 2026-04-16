// ═══════════════════════════════════════════════════════════════════
// CATEGORIES_DAO.DART — CRUD operations for categories
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<KitabDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Watch all non-deleted categories for a user, ordered by sort_order.
  Stream<List<CategoriesTableData>> watchByUser(String userId) {
    return (select(categoriesTable)
          ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Get all non-deleted categories for a user.
  Future<List<CategoriesTableData>> getByUser(String userId) {
    return (select(categoriesTable)
          ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Get a single category by ID.
  Future<CategoriesTableData?> getById(String id) {
    return (select(categoriesTable)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or replace a category (used by sync).
  Future<void> upsert(CategoriesTableCompanion category) {
    return into(categoriesTable).insertOnConflictUpdate(category);
  }

  /// Soft-delete a category.
  Future<void> softDelete(String id) {
    return (update(categoriesTable)..where((c) => c.id.equals(id)))
        .write(CategoriesTableCompanion(deletedAt: Value(DateTime.now())));
  }

  /// Get all categories modified after a given timestamp (for sync pull).
  Future<List<CategoriesTableData>> getModifiedAfter(
      String userId, DateTime after) {
    return (select(categoriesTable)
          ..where(
              (c) => c.userId.equals(userId) & c.updatedAt.isBiggerThanValue(after)))
        .get();
  }
}

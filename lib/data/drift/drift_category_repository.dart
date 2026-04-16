// ═══════════════════════════════════════════════════════════════════
// DRIFT_CATEGORY_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as domain;
import '../repositories/category_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftCategoryRepository implements CategoryRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftCategoryRepository(this._db);

  @override
  Stream<List<domain.Category>> watchByUser(String userId) {
    return _db.categoriesDao.watchByUser(userId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<List<domain.Category>> getByUser(String userId) async {
    final rows = await _db.categoriesDao.getByUser(userId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.Category?> getById(String id) async {
    final row = await _db.categoriesDao.getById(id);
    return row?.toDomain();
  }

  @override
  Future<domain.Category> save(domain.Category category) async {
    final now = DateTime.now();
    final toSave = category.copyWith(
      id: category.id.isEmpty ? _uuid.v4() : category.id,
      updatedAt: now,
    );
    await _db.categoriesDao.upsert(toSave.toCompanion());

    // Enqueue for sync
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('categories'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'), // Full payload built at sync time
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _db.categoriesDao.softDelete(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('categories'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await ((_db.update(_db.categoriesTable)
            ..where((c) => c.id.equals(orderedIds[i])))
          .write(CategoriesTableCompanion(
        sortOrder: Value(i),
        updatedAt: Value(DateTime.now()),
      )));
    }
  }
}

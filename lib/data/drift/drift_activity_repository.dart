// ═══════════════════════════════════════════════════════════════════
// DRIFT_ACTIVITY_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart' as domain;
import '../repositories/activity_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftActivityRepository implements ActivityRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftActivityRepository(this._db);

  @override
  Stream<List<domain.Activity>> watchActiveByUser(String userId) {
    return _db.activitiesDao.watchActiveByUser(userId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<List<domain.Activity>> getByUser(String userId) async {
    final rows = await _db.activitiesDao.getByUser(userId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.Activity>> getByCategory(
      String userId, String categoryId) async {
    final rows = await _db.activitiesDao.getByCategory(userId, categoryId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.Activity?> getById(String id) async {
    final row = await _db.activitiesDao.getById(id);
    return row?.toDomain();
  }

  @override
  Future<domain.Activity> save(domain.Activity activity) async {
    final now = DateTime.now();
    final toSave = activity.copyWith(
      id: activity.id.isEmpty ? _uuid.v4() : activity.id,
      updatedAt: now,
    );
    await _db.activitiesDao.upsert(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('activities'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _db.activitiesDao.softDelete(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('activities'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> setArchived(String id, bool archived) async {
    final now = DateTime.now();
    await (_db.update(_db.activitiesTable)..where((a) => a.id.equals(id)))
        .write(ActivitiesTableCompanion(
      isArchived: Value(archived),
      updatedAt: Value(now),
    ));

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('activities'),
      recordId: Value(id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));
  }
}

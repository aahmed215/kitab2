// ═══════════════════════════════════════════════════════════════════
// DRIFT_ENTRY_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart' as domain;
import '../repositories/entry_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftEntryRepository implements EntryRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftEntryRepository(this._db);

  @override
  Stream<List<domain.Entry>> watchByUser(String userId) {
    return _db.entriesDao.watchByUser(userId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<List<domain.Entry>> getByActivityAndDateRange(
    String userId,
    String activityId,
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await _db.entriesDao.getByActivityAndPeriod(userId, activityId, start, end);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.Entry>> getByPeriod(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final rows = await _db.entriesDao
        .getByPeriod(userId, activityId, periodStart, periodEnd);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.Entry>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.entriesDao.getByDateRange(userId, start, end);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.Entry>> getByRoutineEntry(String routineEntryId) async {
    final rows = await _db.entriesDao.getByRoutineEntry(routineEntryId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.Entry?> getById(String id) async {
    final row = await _db.entriesDao.getById(id);
    return row?.toDomain();
  }

  @override
  Future<domain.Entry> save(domain.Entry entry) async {
    final now = DateTime.now();
    final toSave = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
      updatedAt: now,
    );
    await _db.entriesDao.upsert(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('entries'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _db.entriesDao.softDelete(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('entries'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> unlinkAllForActivity(String userId, String activityId) async {
    // TODO: Implement with Drift
  }
}

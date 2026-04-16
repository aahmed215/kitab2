// ═══════════════════════════════════════════════════════════════════
// DRIFT_ROUTINE_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/routine.dart' as domain;
import '../repositories/routine_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftRoutineRepository implements RoutineRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftRoutineRepository(this._db);

  @override
  Stream<List<domain.Routine>> watchActiveByUser(String userId) {
    return _db.routinesDao.watchActiveByUser(userId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<List<domain.Routine>> getByUser(String userId) async {
    final rows = await _db.routinesDao.getByUser(userId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.Routine?> getById(String id) async {
    final row = await _db.routinesDao.getById(id);
    return row?.toDomain();
  }

  @override
  Future<domain.Routine> save(domain.Routine routine) async {
    final now = DateTime.now();
    final toSave = routine.copyWith(
      id: routine.id.isEmpty ? _uuid.v4() : routine.id,
      updatedAt: now,
    );
    await _db.routinesDao.upsert(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('routines'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> delete(String id) async {
    await _db.routinesDao.softDelete(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('routines'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ─── Routine Entries ───

  @override
  Future<List<domain.RoutineEntry>> getEntriesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await _db.routinesDao.getEntriesByDateRange(userId, start, end);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.RoutineEntry?> getEntryById(String id) async {
    final row = await _db.routinesDao.getEntryById(id);
    return row?.toDomain();
  }

  @override
  Future<domain.RoutineEntry> saveEntry(domain.RoutineEntry entry) async {
    final now = DateTime.now();
    final toSave = entry.copyWith(
      id: entry.id.isEmpty ? _uuid.v4() : entry.id,
      updatedAt: now,
    );
    await _db.routinesDao.upsertEntry(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('routine_entries'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }
}

// ═══════════════════════════════════════════════════════════════════
// DRIFT_CONDITION_REPOSITORY.DART — Local SQLite implementation
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/condition.dart' as domain;
import '../repositories/condition_repository.dart';
import 'converters.dart';
import 'database.dart';

class DriftConditionRepository implements ConditionRepository {
  final KitabDatabase _db;
  static const _uuid = Uuid();

  DriftConditionRepository(this._db);

  // ─── Presets ───

  @override
  Future<List<domain.ConditionPreset>> getPresetsByUser(String userId) async {
    final rows = await _db.conditionsDao.getPresetsByUser(userId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.ConditionPreset> savePreset(
      domain.ConditionPreset preset) async {
    final toSave = preset.copyWith(
      id: preset.id.isEmpty ? _uuid.v4() : preset.id,
    );
    await _db.conditionsDao.upsertPreset(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('condition_presets'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));

    return toSave;
  }

  @override
  Future<void> deletePreset(String id) async {
    await _db.conditionsDao.softDeletePreset(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('condition_presets'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }

  // ─── Condition Instances ───

  @override
  Stream<List<domain.Condition>> watchActiveByUser(String userId) {
    return _db.conditionsDao.watchActiveByUser(userId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<List<domain.Condition>> getByUser(String userId) async {
    final rows = await _db.conditionsDao.getByUser(userId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<domain.Condition>> getActiveOnDate(
      String userId, DateTime date) async {
    final rows = await _db.conditionsDao.getActiveOnDate(userId, date);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<domain.Condition> saveCondition(domain.Condition condition) async {
    final now = DateTime.now();
    final toSave = condition.copyWith(
      id: condition.id.isEmpty ? _uuid.v4() : condition.id,
      updatedAt: now,
    );
    await _db.conditionsDao.upsertCondition(toSave.toCompanion());

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('conditions'),
      recordId: Value(toSave.id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));

    return toSave;
  }

  @override
  Future<void> endCondition(String id, DateTime endDate) async {
    final now = DateTime.now();
    await (_db.update(_db.conditionsTable)..where((c) => c.id.equals(id)))
        .write(ConditionsTableCompanion(
      endDate: Value(endDate),
      updatedAt: Value(now),
    ));

    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('conditions'),
      recordId: Value(id),
      operation: const Value('upsert'),
      payload: const Value('{}'),
      createdAt: Value(now),
    ));
  }

  @override
  Future<void> deleteCondition(String id) async {
    await _db.conditionsDao.softDeleteCondition(id);
    await _db.syncDao.enqueue(SyncQueueTableCompanion(
      id: Value(_uuid.v4()),
      tableName_: const Value('conditions'),
      recordId: Value(id),
      operation: const Value('delete'),
      payload: const Value('{}'),
      createdAt: Value(DateTime.now()),
    ));
  }
}

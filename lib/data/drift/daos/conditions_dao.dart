// ═══════════════════════════════════════════════════════════════════
// CONDITIONS_DAO.DART — CRUD for condition presets and instances
// Grouped together because presets and conditions are always
// queried in tandem (e.g., showing active conditions with labels).
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'conditions_dao.g.dart';

@DriftAccessor(tables: [ConditionPresetsTable, ConditionsTable])
class ConditionsDao extends DatabaseAccessor<KitabDatabase>
    with _$ConditionsDaoMixin {
  ConditionsDao(super.db);

  // ─── Presets ───

  /// Get all non-deleted presets for a user.
  Future<List<ConditionPresetsTableData>> getPresetsByUser(String userId) {
    return (select(conditionPresetsTable)
          ..where((p) => p.userId.equals(userId) & p.deletedAt.isNull()))
        .get();
  }

  /// Insert or replace a preset.
  Future<void> upsertPreset(ConditionPresetsTableCompanion preset) {
    return into(conditionPresetsTable).insertOnConflictUpdate(preset);
  }

  /// Soft-delete a preset.
  Future<void> softDeletePreset(String id) {
    return (update(conditionPresetsTable)..where((p) => p.id.equals(id)))
        .write(ConditionPresetsTableCompanion(
            deletedAt: Value(DateTime.now())));
  }

  // ─── Condition Instances ───

  /// Watch active conditions (no end date) for a user.
  Stream<List<ConditionsTableData>> watchActiveByUser(String userId) {
    return (select(conditionsTable)
          ..where((c) =>
              c.userId.equals(userId) &
              c.deletedAt.isNull() &
              c.endDate.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.startDate)]))
        .watch();
  }

  /// Get all non-deleted conditions for a user.
  Future<List<ConditionsTableData>> getByUser(String userId) {
    return (select(conditionsTable)
          ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.desc(c.startDate)]))
        .get();
  }

  /// Check if a condition was active on a specific date.
  /// Used by the period engine to auto-excuse periods.
  Future<List<ConditionsTableData>> getActiveOnDate(
      String userId, DateTime date) {
    return (select(conditionsTable)
          ..where((c) =>
              c.userId.equals(userId) &
              c.deletedAt.isNull() &
              c.startDate.isSmallerOrEqualValue(date) &
              (c.endDate.isNull() | c.endDate.isBiggerOrEqualValue(date))))
        .get();
  }

  /// Insert or replace a condition.
  Future<void> upsertCondition(ConditionsTableCompanion condition) {
    return into(conditionsTable).insertOnConflictUpdate(condition);
  }

  /// Soft-delete a condition.
  Future<void> softDeleteCondition(String id) {
    return (update(conditionsTable)..where((c) => c.id.equals(id)))
        .write(ConditionsTableCompanion(deletedAt: Value(DateTime.now())));
  }
}

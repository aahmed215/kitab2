// ═══════════════════════════════════════════════════════════════════
// CONDITION_REPOSITORY.DART — Abstract interface for conditions
// Handles both presets and active condition instances.
// ═══════════════════════════════════════════════════════════════════

import '../models/condition.dart';

/// Contract for condition data access.
abstract class ConditionRepository {
  // ─── Presets ───

  /// Get all condition presets for a user.
  Future<List<ConditionPreset>> getPresetsByUser(String userId);

  /// Create or update a preset.
  Future<ConditionPreset> savePreset(ConditionPreset preset);

  /// Soft-delete a preset.
  Future<void> deletePreset(String id);

  // ─── Condition Instances ───

  /// Watch active (ongoing) conditions for a user.
  Stream<List<Condition>> watchActiveByUser(String userId);

  /// Get all conditions for a user (including ended).
  Future<List<Condition>> getByUser(String userId);

  /// Check if any condition was active on a specific date.
  /// Used by the period engine to auto-excuse.
  Future<List<Condition>> getActiveOnDate(String userId, DateTime date);

  /// Create or update a condition.
  Future<Condition> saveCondition(Condition condition);

  /// End a condition (set end_date).
  Future<void> endCondition(String id, DateTime endDate);

  /// Soft-delete a condition.
  Future<void> deleteCondition(String id);
}

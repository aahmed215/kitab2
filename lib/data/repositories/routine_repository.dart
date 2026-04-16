// ═══════════════════════════════════════════════════════════════════
// ROUTINE_REPOSITORY.DART — Abstract interface for routines
// ═══════════════════════════════════════════════════════════════════

import '../models/routine.dart';

/// Contract for routine data access.
abstract class RoutineRepository {
  /// Watch all active (non-archived) routines for a user.
  Stream<List<Routine>> watchActiveByUser(String userId);

  /// Get all routines for a user (including archived).
  Future<List<Routine>> getByUser(String userId);

  /// Get a single routine by ID.
  Future<Routine?> getById(String id);

  /// Create or update a routine.
  Future<Routine> save(Routine routine);

  /// Soft-delete a routine.
  Future<void> delete(String id);

  // ─── Routine Entries (Sessions) ───

  /// Get routine entries for a date range.
  Future<List<RoutineEntry>> getEntriesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Get a single routine entry by ID.
  Future<RoutineEntry?> getEntryById(String id);

  /// Create or update a routine entry.
  Future<RoutineEntry> saveEntry(RoutineEntry entry);
}

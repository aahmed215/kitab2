// ═══════════════════════════════════════════════════════════════════
// ENTRY_REPOSITORY.DART — Abstract interface for entry (log) data
// ═══════════════════════════════════════════════════════════════════

import '../models/entry.dart';

/// Contract for activity entry (log) data access.
abstract class EntryRepository {
  /// Watch all entries for a user, newest first.
  Stream<List<Entry>> watchByUser(String userId);

  /// Get entries for a specific activity within a date range.
  /// Used by the goal engine to evaluate period completion.
  Future<List<Entry>> getByActivityAndDateRange(
    String userId,
    String activityId,
    DateTime start,
    DateTime end,
  );

  /// Get entries linked to a specific period (Layer 2 linkage).
  Future<List<Entry>> getByPeriod(
    String userId,
    String activityId,
    DateTime periodStart,
    DateTime periodEnd,
  );

  /// Get entries for a date range (home screen "today" view).
  Future<List<Entry>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );

  /// Get entries linked to a routine entry.
  Future<List<Entry>> getByRoutineEntry(String routineEntryId);

  /// Get a single entry by ID.
  Future<Entry?> getById(String id);

  /// Create or update an entry. Returns the saved entry.
  Future<Entry> save(Entry entry);

  /// Soft-delete an entry.
  Future<void> delete(String id);

  /// Unlink all entries for an activity from their periods.
  Future<void> unlinkAllForActivity(String userId, String activityId);
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVITY_REPOSITORY.DART — Abstract interface for activity data
// ═══════════════════════════════════════════════════════════════════

import '../models/activity.dart';

/// Contract for activity template data access.
abstract class ActivityRepository {
  /// Watch all active (non-archived) activities for a user.
  Stream<List<Activity>> watchActiveByUser(String userId);

  /// Get all activities for a user (including archived).
  Future<List<Activity>> getByUser(String userId);

  /// Get activities in a specific category.
  Future<List<Activity>> getByCategory(String userId, String categoryId);

  /// Get a single activity by ID.
  Future<Activity?> getById(String id);

  /// Create or update an activity. Returns the saved activity.
  Future<Activity> save(Activity activity);

  /// Soft-delete an activity.
  Future<void> delete(String id);

  /// Archive/unarchive an activity.
  Future<void> setArchived(String id, bool archived);
}

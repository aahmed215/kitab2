// ═══════════════════════════════════════════════════════════════════
// USER_REPOSITORY.DART — Abstract interface for user profiles
// ═══════════════════════════════════════════════════════════════════

import '../models/user_profile.dart';

/// Contract for user profile data access.
abstract class UserRepository {
  /// Get a user profile by ID.
  Future<UserProfile?> getById(String id);

  /// Watch the current user's profile reactively.
  Stream<UserProfile?> watchById(String id);

  /// Create or update a user profile.
  Future<UserProfile> save(UserProfile profile);

  /// Update only the settings portion.
  Future<void> updateSettings(String userId, UserSettings settings);

  /// Check if a username is available.
  Future<bool> isUsernameAvailable(String username);
}

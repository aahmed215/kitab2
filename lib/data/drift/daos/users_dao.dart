// ═══════════════════════════════════════════════════════════════════
// USERS_DAO.DART — CRUD for user profiles
// Also handles user_reports and blocked_users since they're
// user-management concerns.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable, UserReportsTable, BlockedUsersTable])
class UsersDao extends DatabaseAccessor<KitabDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  // ─── User Profile ───

  /// Get a user by ID.
  Future<UsersTableData?> getById(String id) {
    return (select(usersTable)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch the current user's profile for reactive UI updates.
  Stream<UsersTableData?> watchById(String id) {
    return (select(usersTable)..where((u) => u.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Insert or replace a user profile (used by sync and auth).
  Future<void> upsert(UsersTableCompanion user) {
    return into(usersTable).insertOnConflictUpdate(user);
  }

  /// Update user settings JSON.
  Future<void> updateSettings(String userId, String settingsJson) {
    return (update(usersTable)..where((u) => u.id.equals(userId)))
        .write(UsersTableCompanion(
          settings: Value(settingsJson),
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ─── Blocked Users ───

  /// Get all users blocked by this user.
  Future<List<BlockedUsersTableData>> getBlockedUsers(String userId) {
    return (select(blockedUsersTable)
          ..where((b) => b.userId.equals(userId) & b.deletedAt.isNull()))
        .get();
  }

  /// Block a user.
  Future<void> blockUser(BlockedUsersTableCompanion block) {
    return into(blockedUsersTable).insertOnConflictUpdate(block);
  }

  /// Unblock a user (soft delete).
  Future<void> unblockUser(String id) {
    return (update(blockedUsersTable)..where((b) => b.id.equals(id)))
        .write(BlockedUsersTableCompanion(deletedAt: Value(DateTime.now())));
  }

  // ─── User Reports ───

  /// Submit a report.
  Future<void> submitReport(UserReportsTableCompanion report) {
    return into(userReportsTable).insert(report);
  }
}

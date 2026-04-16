// ═══════════════════════════════════════════════════════════════════
// NOTIFICATIONS_DAO.DART — CRUD for in-app notifications
// Notifications are ephemeral — tap executes action and deletes.
// ═══════════════════════════════════════════════════════════════════

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drift_tables.dart';

part 'notifications_dao.g.dart';

@DriftAccessor(tables: [NotificationsTable])
class NotificationsDao extends DatabaseAccessor<KitabDatabase>
    with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  /// Watch all non-deleted notifications for a user, newest first.
  Stream<List<NotificationsTableData>> watchByUser(String userId) {
    return (select(notificationsTable)
          ..where((n) => n.userId.equals(userId) & n.deletedAt.isNull())
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .watch();
  }

  /// Get count of undeleted notifications (for badge).
  Stream<int> watchCount(String userId) {
    final count = notificationsTable.id.count();
    final query = selectOnly(notificationsTable)
      ..addColumns([count])
      ..where(notificationsTable.userId.equals(userId) &
          notificationsTable.deletedAt.isNull());
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Insert a notification.
  Future<void> insert(NotificationsTableCompanion notification) {
    return into(notificationsTable).insertOnConflictUpdate(notification);
  }

  /// Soft-delete a notification (after tap or swipe dismiss).
  Future<void> softDelete(String id) {
    return (update(notificationsTable)..where((n) => n.id.equals(id)))
        .write(NotificationsTableCompanion(deletedAt: Value(DateTime.now())));
  }

  /// Soft-delete all notifications for a user.
  Future<void> softDeleteAll(String userId) {
    return (update(notificationsTable)
          ..where((n) => n.userId.equals(userId) & n.deletedAt.isNull()))
        .write(NotificationsTableCompanion(deletedAt: Value(DateTime.now())));
  }
}

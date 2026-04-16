// ═══════════════════════════════════════════════════════════════════
// NOTIFICATIONS_SCREEN.DART — In-App Notification List
// Tap → execute action + delete. Swipe → delete without action.
// No read/unread state — notifications are ephemeral.
// See SPEC.md §14.2 for specification.
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/database_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/kitab_theme.dart';
import '../../data/models/notification.dart';
import '../../data/supabase/supabase_helpers.dart';

/// Watch all notifications for the current user.
final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (kIsWeb) {
    // Web: stream from Supabase
    final controller = StreamController<List<AppNotification>>();
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((rows) {
      final notifications = rows
          .where((r) => r['deleted_at'] == null)
          .map((r) => AppNotification.fromJson(toCamelCase(r)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(notifications);
    });
    return controller.stream;
  }

  // Native: stream from Drift
  final db = ref.watch(databaseProvider);
  return db.notificationsDao.watchByUser(userId).map(
        (rows) => rows
            .map((r) => AppNotification(
                  id: r.id,
                  userId: r.userId,
                  type: r.type,
                  title: r.title,
                  description: r.description,
                  actionType: r.actionType,
                  actionData: null,
                  createdAt: r.createdAt,
                ))
            .toList(),
      );
});

/// Notification count for badge.
final notificationCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (kIsWeb) {
    // Web: count from Supabase stream
    return ref.watch(notificationsProvider.stream).map(
          (notifications) => notifications.length,
        );
  }

  final db = ref.watch(databaseProvider);
  return db.notificationsDao.watchCount(userId);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: KitabTypography.h2),
        actions: [
          notificationsAsync.when(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () async {
                      final userId = ref.read(currentUserIdProvider);
                      if (kIsWeb) {
                        await Supabase.instance.client
                            .from('notifications')
                            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
                            .eq('user_id', userId)
                            .isFilter('deleted_at', null);
                      } else {
                        await ref
                            .read(databaseProvider)
                            .notificationsDao
                            .softDeleteAll(userId);
                      }
                    },
                    child: const Text('Clear All'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: KitabSpacing.md),
                  Text('No notifications', style: KitabTypography.h3),
                  const SizedBox(height: KitabSpacing.sm),
                  Text(
                    "You're all caught up!",
                    style: KitabTypography.body
                        .copyWith(color: KitabColors.gray500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(KitabSpacing.lg),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(
                notification: notif,
                onTap: () => _handleTap(context, ref, notif),
                onDismiss: () => _dismiss(ref, notif),
                fmt: ref.watch(dateFormatterProvider),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _handleTap(
      BuildContext context, WidgetRef ref, AppNotification notif) {
    // Execute action based on type
    switch (notif.actionType) {
      case 'navigate_activity':
        // TODO: Navigate to activity detail
        break;
      case 'navigate_social':
        // TODO: Navigate to social tab
        break;
      case 'navigate_competition':
        // TODO: Navigate to competition detail
        break;
      case 'trigger_sync':
        // TODO: Trigger manual sync
        break;
    }

    // Delete after tap (ephemeral)
    _dismiss(ref, notif);
  }

  void _dismiss(WidgetRef ref, AppNotification notif) {
    if (kIsWeb) {
      Supabase.instance.client.from('notifications').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notif.id);
    } else {
      ref.read(databaseProvider).notificationsDao.softDelete(notif.id);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final KitabDateFormat fmt;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: KitabColors.error.withValues(alpha: 0.1),
          borderRadius: KitabRadii.borderMd,
        ),
        child: const Icon(Icons.delete_outline, color: KitabColors.error),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.only(bottom: KitabSpacing.sm),
        child: ListTile(
          leading: _icon(notification.type),
          title: Text(notification.title, style: KitabTypography.body),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.description != null)
                Text(notification.description!,
                    style: KitabTypography.bodySmall),
              Text(
                _timeAgo(notification.createdAt, fmt),
                style: KitabTypography.caption
                    .copyWith(color: KitabColors.gray400),
              ),
            ],
          ),
          onTap: onTap,
          trailing:
              const Icon(Icons.chevron_right, color: KitabColors.gray400),
        ),
      ),
    );
  }

  Widget _icon(String type) {
    final (IconData icon, Color color) = switch (type) {
      'streak_risk' => (Icons.warning_amber, KitabColors.warning),
      'streak_milestone' => (Icons.emoji_events, KitabColors.accent),
      'reminder' => (Icons.alarm, KitabColors.primary),
      'friend_request' => (Icons.person_add, KitabColors.info),
      'competition_invite' => (Icons.emoji_events, KitabColors.primary),
      'competition_update' => (Icons.leaderboard, KitabColors.success),
      'sync_issue' => (Icons.sync_problem, KitabColors.error),
      'condition_reminder' => (Icons.healing, KitabColors.warning),
      _ => (Icons.notifications, KitabColors.gray500),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _timeAgo(DateTime dt, KitabDateFormat fmt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return fmt.monthDay(dt);
  }
}

// ═══════════════════════════════════════════════════════════════════
// NOTIFICATION.DART — In-App Notification Data Model
// Ephemeral — exists or doesn't, no read/unread state.
// Maps to the `notifications` table in Supabase.
// See SPEC.md §14.2 for full specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// An in-app notification. Tapping executes the action and deletes the
/// notification. Swiping deletes without executing. No read/unread state.
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,

    /// Notification type: 'streak_risk', 'streak_milestone', 'reminder',
    /// 'friend_request', 'competition_invite', 'competition_update',
    /// 'sync_issue', 'condition_reminder'
    required String type,

    /// Headline text
    required String title,

    /// Detail text
    String? description,

    /// What happens on tap: 'navigate_activity', 'navigate_social',
    /// 'navigate_competition', 'trigger_sync', etc.
    String? actionType,

    /// Data needed for the action: { activity_id, competition_id, etc. }
    Map<String, dynamic>? actionData,

    /// When the notification was generated
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

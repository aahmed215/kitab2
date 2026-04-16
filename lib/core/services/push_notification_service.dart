// ═══════════════════════════════════════════════════════════════════
// PUSH_NOTIFICATION_SERVICE.DART — FCM/APNs Push Delivery
// Handles push notification registration, token management,
// and deep link routing when a push is tapped.
// ═══════════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler (must be top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background notification received — data is stored by FCM
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize push notifications.
  Future<void> initialize({
    required void Function(String? route) onNotificationTap,
  }) async {
    // Skip on web for now
    if (kIsWeb) return;

    // Request permission (iOS shows a dialog, Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications (for foreground display)
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        final route = response.payload;
        onNotificationTap(route);
      },
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Tap on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'] as String?;
      onNotificationTap(route);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'] as String?;
      onNotificationTap(route);
    }

    // Get FCM token for this device
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  /// Display a local notification when app is in foreground.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Check if this is a private activity notification
    final isPrivate = message.data['is_private'] == 'true';
    final title = notification.title ?? 'Kitab';
    final body = isPrivate ? 'Activity reminder' : (notification.body ?? '');

    await _localNotifications.show(
      notification.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kitab_default',
          'Kitab Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: message.data['route'] as String?,
    );
  }

  /// Save FCM token to Supabase for server-side push delivery.
  Future<void> _saveTokenToSupabase(String token) async {
    // TODO: Call Supabase to store the device token
    // await supabase.from('device_tokens').upsert({
    //   'user_id': currentUserId,
    //   'token': token,
    //   'platform': Platform.isIOS ? 'ios' : 'android',
    //   'updated_at': DateTime.now().toIso8601String(),
    // });
  }
}

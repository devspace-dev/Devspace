import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM background handling
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'devspace_high',
    'DevSpace Notifications',
    description: 'Likes, follows, comments and more.',
    importance: Importance.high,
  );

  Future<void> init(String uid) async {
    if (Firebase.apps.isEmpty) {
      debugPrint('Notification initialization skipped because Firebase is not configured.');
      return;
    }

    try {
      // Request permission (iOS + Android 13+)
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      // Local notifications setup
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // Create the high-priority Android channel
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Save FCM token to Supabase
      final token = await _fcm.getToken();
      if (token != null) {
        await SupabaseService.instance.updateUser(uid, {'fcmToken': token});
      }

      // Refresh token listener
      _fcm.onTokenRefresh.listen((newToken) {
        SupabaseService.instance.updateUser(uid, {'fcmToken': newToken});
      });

      // Foreground messages → show local notification
      FirebaseMessaging.onMessage.listen(_showLocalNotification);
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> notifyLike({
    required String toUid,
    required String fromUid,
    required String postId,
    required String fromName,
  }) async {
    if (toUid == fromUid) return;
    await SupabaseService.instance.pushNotification(
      toUid: toUid,
      fromUid: fromUid,
      type: 'like',
      postId: postId,
      message: '$fromName liked your post',
    );
  }

  Future<void> notifyComment({
    required String toUid,
    required String fromUid,
    required String postId,
    required String fromName,
    required String commentText,
  }) async {
    if (toUid == fromUid) return;
    await SupabaseService.instance.pushNotification(
      toUid: toUid,
      fromUid: fromUid,
      type: 'comment',
      postId: postId,
      message: '$fromName commented: "$commentText"',
    );
  }

  Future<void> notifyFollow({
    required String toUid,
    required String fromUid,
    required String fromName,
  }) async {
    if (toUid == fromUid) return;
    await SupabaseService.instance.pushNotification(
      toUid: toUid,
      fromUid: fromUid,
      type: 'follow',
      message: '$fromName started following you',
    );
  }
}

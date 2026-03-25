import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs.
  // You can optionally update Firestore here (e.g. increment unread count).
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Android channel
  static const _channel = AndroidNotificationChannel(
    'devspace_high',
    'DevSpace Notifications',
    description: 'Likes, follows, comments and more.',
    importance: Importance.high,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALISE (call once in main.dart after Firebase.initializeApp)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> init(String uid) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

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

    // Save FCM token to Firestore so backend can send targeted pushes
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseService.instance.updateUser(uid, {'fcmToken': token});
    }

    // Refresh token listener
    _fcm.onTokenRefresh.listen((newToken) {
      FirebaseService.instance.updateUser(uid, {'fcmToken': newToken});
    });

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHOW LOCAL NOTIFICATION
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // SEND NOTIFICATION VIA FIRESTORE TRIGGER
  // (In production you'd use Cloud Functions — this writes to Firestore
  //  and a Cloud Function reads it and calls FCM server API.)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> notifyLike({
    required String toUid,
    required String fromUid,
    required String postId,
    required String fromName,
  }) async {
    if (toUid == fromUid) return; // don't notify yourself
    await FirebaseService.instance.pushNotification(
      toUid:   toUid,
      fromUid: fromUid,
      type:    'like',
      postId:  postId,
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
    await FirebaseService.instance.pushNotification(
      toUid:   toUid,
      fromUid: fromUid,
      type:    'comment',
      postId:  postId,
      message: '$fromName commented: "$commentText"',
    );
  }

  Future<void> notifyFollow({
    required String toUid,
    required String fromUid,
    required String fromName,
  }) async {
    if (toUid == fromUid) return;
    await FirebaseService.instance.pushNotification(
      toUid:   toUid,
      fromUid: fromUid,
      type:    'follow',
      message: '$fromName started following you',
    );
  }
}

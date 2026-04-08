import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'devspace_high',
    'DevSpace Notifications',
    description: 'Likes, follows, comments and more.',
    importance: Importance.high,
  );

  Future<void> init(String uid) async {
    try {
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

      await _requestPermissions();

      if (kDebugMode) {
        debugPrint('Notification service initialized for $uid.');
      }
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> showLocalNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final android = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    await _local.show(
      id.hashCode,
      title,
      body,
      details,
      payload: payload,
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

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

      if (kDebugMode) {
          print('Notification service initialized (Local notifications only).');
      }
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
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

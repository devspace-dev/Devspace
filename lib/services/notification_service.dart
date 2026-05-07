import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _notificationStreamController = StreamController<String?>.broadcast();
  Stream<String?> get notificationResponseStream => _notificationStreamController.stream;

  static const _channel = AndroidNotificationChannel(
    'devspace_high',
    'DevSpace Notifications',
    description: 'Likes, follows, comments and more.',
    importance: Importance.high,
  );

  Future<void> init(String uid) async {
    try {
      // 1. Firebase Messaging Setup
      final fcm = FirebaseMessaging.instance;
      
      // Request permissions (especially for iOS)
      await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Foreground notifications display
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null) {
          showLocalNotification(
            id: message.messageId ?? DateTime.now().toString(),
            title: notification.title ?? 'DevSpace',
            body: notification.body ?? '',
          );
        }
      });

      // 2. Local notifications setup
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            _notificationStreamController.add(response.payload);
          }
        },
      );

      // Create the high-priority Android channel
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _requestPermissions();

      // Subscribe every signed-in device to one common topic so founders
      // can send simple broadcast notifications from Firebase Console.
      await fcm.subscribeToTopic('all_users');

      // 3. Save FCM Token to Supabase when the column exists.
      try {
        final token = await fcm.getToken();
        if (token != null) {
          await SupabaseService.instance.updateFcmToken(uid, token);
        }
      } catch (e) {
        debugPrint('Failed to save FCM token: $e');
      }

      // Listen for token refreshes
      fcm.onTokenRefresh.listen((newToken) {
        SupabaseService.instance.updateFcmToken(uid, newToken).catchError((
          Object error,
        ) {
          debugPrint('Failed to refresh FCM token: $error');
        });
      });

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
      id: id.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
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

  Future<void> notifyNewMission({
    required String title,
    required String techStack,
  }) async {
    await SupabaseService.instance.sendBroadcastNotification(
      title: 'New Daily Mission! 🚀',
      body: 'Today\'s challenge: $title ($techStack). Solve it to earn Aura points!',
      type: 'mission',
    );
  }
}

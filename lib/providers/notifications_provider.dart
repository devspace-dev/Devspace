import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  StreamSubscription? _subscription;
  String? _lastNotificationId;

  void init(String uid) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = SupabaseService.instance.streamNotifications(uid).listen(
      (data) {
        // If we have new notifications that are unread, show a local notification
        if (data.isNotEmpty) {
          final newest = data.first;
          if (!newest.read &&
              newest.id != _lastNotificationId &&
              DateTime.now().difference(newest.createdAt).inMinutes < 5) {
            _lastNotificationId = newest.id;
            _showLocal(newest);
          }
        }

        _notifications = data;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _error = 'Failed to load notifications: $error';
        notifyListeners();
      },
    );
  }

  void _showLocal(NotificationModel n) {
    String title = 'DevSpace';
    if (n.type == 'like') title = 'New Like ⚡';
    if (n.type == 'comment') title = 'New Comment 💬';
    if (n.type == 'follow') title = 'New Follower 👥';
    if (n.type == 'message') title = 'New Message ✉️';
    if (n.type == 'solved') title = 'Solution Accepted ✅';

    NotificationService.instance.showLocalNotification(
      id: n.id,
      title: title,
      body: n.message,
    );
  }

  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> markAsRead(String id) async {
    await SupabaseService.instance.markNotificationAsRead(id);
  }

  Future<void> markAllAsRead(String uid) async {
    await SupabaseService.instance.markAllNotificationsAsRead(uid);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

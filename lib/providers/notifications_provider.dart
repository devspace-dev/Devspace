import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  StreamSubscription? _subscription;

  void init(String uid) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = SupabaseService.instance.streamNotifications(uid).listen(
      (data) {
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

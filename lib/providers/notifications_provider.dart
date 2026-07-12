import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../main.dart' as import_main;

class NotificationsProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  StreamSubscription? _subscription;
  final Set<String> _seenNotificationIds = {};

  void init(String uid) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool isFirstEvent = true;

    _subscription = SupabaseService.instance.streamNotifications(uid).listen(
      (data) {
        if (isFirstEvent) {
          isFirstEvent = false;
          // On first load, just record everything as seen to prevent popups
          for (final n in data) {
            _seenNotificationIds.add(n.id);
          }
        } else {
          // If we have new notifications that are unread, show a local notification
          for (final n in data) {
            if (!n.read &&
                !_seenNotificationIds.contains(n.id) &&
                DateTime.now().difference(n.createdAt).inMinutes < 5) {
              _seenNotificationIds.add(n.id);
              _showLocal(n);
            }
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
    if (n.type == 'pr_request') title = 'Collaboration Request 🤝';
    if (n.type == 'duel_invite') title = 'New Duel Challenge! ⚔️';

    final payload = jsonEncode({
      'type': n.type,
      'postId': n.postId,
      'questionId': n.questionId,
      'fromUid': n.fromUid,
      'id': n.id,
    });

    NotificationService.instance.showLocalNotification(
      id: n.id,
      title: title,
      body: n.message,
      payload: payload,
    );

    // Show in-app popup
    import_main.rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(n.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1E1E), // AppColors.bg2 (approx)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }

  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    _notifications = _notifications.map<NotificationModel>((n) {
      if (n.id == id) {
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
    notifyListeners();

    try {
      await SupabaseService.instance.markNotificationAsRead(id);
    } catch (e) {
      debugPrint('Failed to mark notification read: $e');
    }
  }

  Future<void> markAllAsRead(String uid) async {
    // Optimistic UI update
    _notifications = _notifications
        .map<NotificationModel>((n) => n.copyWith(read: true))
        .toList();
    notifyListeners();

    try {
      await SupabaseService.instance.markAllNotificationsAsRead(uid);
    } catch (e) {
      debugPrint('Failed to mark all notifications read: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

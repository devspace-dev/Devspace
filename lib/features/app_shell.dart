import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../core/widgets/ds_nav_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/users_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/questions_provider.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/question_detail_screen.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StreamSubscription<String?>? _notificationSubscription;
  dynamic _duelRequestsSubscription;
  String? _lastInitializedUid;

  @override
  void initState() {
    super.initState();
    _initProviders();
    _setupNotificationTapListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _duelRequestsSubscription?.unsubscribe();
    super.dispose();
  }

  void _initProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final auth = context.read<AuthProvider>();

        context.read<UsersProvider>().fetchUsers();
        context.read<PostsProvider>().fetchFeed();
        context.read<QuestionsProvider>().fetchQuestions();

        auth.addListener(_onAuthChanged);
        _onAuthChanged();
      } catch (e) {
        debugPrint('AppShell initProviders caught: $e');
      }
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserOrNull;

    if (user != null) {
      if (_lastInitializedUid == user.id) return;
      _lastInitializedUid = user.id;

      try {
        NotificationService.instance.init(user.id);
        context.read<NotificationsProvider>().init(user.id);
        context.read<MessagesProvider>().init(user.id);
        context.read<EngagementProvider>().fetchOverview();
        _setupDuelRequestsListener(user.id);
      } catch (e) {
        debugPrint('Provider initialization in AppShell failed: $e');
      }
    } else {
      _lastInitializedUid = null;
      _duelRequestsSubscription?.unsubscribe();
      _duelRequestsSubscription = null;
    }
  }

  void _setupDuelRequestsListener(String userId) {
    _duelRequestsSubscription?.unsubscribe();
    _duelRequestsSubscription = SupabaseService.instance.listenToIncomingDuelRequests(userId, (request) {
      if (!mounted) return;
      _showIncomingDuelDialog(request);
    });
  }

  void _showIncomingDuelDialog(Map<String, dynamic> request) async {
    final senderId = request['sender_id'].toString();
    UserModel? sender = context.read<UsersProvider>().getUserById(senderId);
    if (sender == null) {
      try {
        sender = await context.read<UsersProvider>().getUser(senderId);
      } catch (_) {}
    }
    if (!mounted || sender == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Ds.surface,
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Ds.aura),
            SizedBox(width: 8),
            Text('CHALLENGE!', style: TextStyle(color: Ds.bone, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '${sender!.name} challenged you to a duel in ${request['category']}!',
          style: const TextStyle(color: Ds.muted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SupabaseService.instance.updateDuelRequestStatus(request['id'].toString(), 'declined');
            },
            child: const Text('DECLINE', style: TextStyle(color: Ds.hot)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Ds.aura),
            onPressed: () {
              Navigator.pop(ctx);
              SupabaseService.instance.updateDuelRequestStatus(request['id'].toString(), 'accepted');
            },
            child: const Text('ACCEPT', style: TextStyle(color: Ds.onAura, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _setupNotificationTapListener() {
    _notificationSubscription = NotificationService.instance.notificationResponseStream.listen((payload) async {
      if (payload == null || !mounted) return;
      try {
        final data = jsonDecode(payload);
        final String type = data['type'] ?? '';
        final String? fromUid = data['fromUid'] ?? data['from_uid'];
        final String? questionId = data['questionId'] ?? data['question_id'];

        if (type == 'message' && fromUid != null) {
          final me = context.read<AuthProvider>().currentUserOrNull;
          if (me == null) return;

          final msgP = context.read<MessagesProvider>();
          final conv = msgP.conversations.firstWhere(
            (c) => c.participants.contains(fromUid),
            orElse: () => ConversationModel(
              id: '',
              participants: [me.id, fromUid],
              createdAt: DateTime.now(),
            ),
          );

          UserModel? other = context.read<UsersProvider>().getUserById(fromUid);
          if (other == null) {
            try {
              other = await context.read<UsersProvider>().getUser(fromUid);
            } catch (_) {}
          }
          if (other != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(conversation: conv, otherUser: other!),
              ),
            );
          }
        } else if (type == 'pr_request' || type == 'solved') {
          if (questionId != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuestionDetailScreen(questionId: questionId)),
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to handle notification tap in AppShell: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserOrNull;
    final unreadCount = context.select<NotificationsProvider, int>((p) => p.unreadCount);

    final initials = (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'U';

    return Scaffold(
      backgroundColor: Ds.ink,
      body: widget.shell,
      bottomNavigationBar: DsNavBar(
        currentIndex: widget.shell.currentIndex,
        onTap: (index) {
          widget.shell.goBranch(
            index,
            initialLocation: index == widget.shell.currentIndex,
          );
        },
        ranksDot: unreadCount > 0,
        profileAvatarUrl: user?.avatar,
        profileInitials: initials,
      ),
    );
  }
}

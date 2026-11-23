import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_card.dart';
import '../core/widgets/ds_nav_bar.dart';
import '../core/widgets/glitch.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/users_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/practice_provider.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../models/conversation_model.dart';
import '../models/user_model.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/question_detail_screen.dart';
import '../widgets/duel_invite_dialog.dart';
import 'path/providers/path_provider.dart';
import 'tour/services/tour_controller.dart';
import 'tour/widgets/tour_host.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  StreamSubscription<String?>? _notificationSubscription;
  dynamic _duelRequestsSubscription;
  String? _lastInitializedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initProviders();
    _setupNotificationTapListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _duelRequestsSubscription?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final tour = context.read<TourController>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      tour.pauseTour();
    } else if (state == AppLifecycleState.resumed) {
      tour.resumeTour();
    }
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

        // Initialize Tour for user
        final tour = context.read<TourController>();
        final pathProvider = context.read<PathProvider>();
        final practiceProvider = context.read<PracticeProvider>();
        final postsProvider = context.read<PostsProvider>();
        tour.hasActiveRoadmapGetter = () => pathProvider.hasActiveRoadmap;
        tour.practiceCompletionsCountGetter = () => practiceProvider.totalCompletedCount;
        tour.postsCountGetter = () => postsProvider.postsForUser(user.id).length;
        tour.hasEventsTabGetter = () => true;
        tour.routeNavigator = (route) {
          if (mounted) context.go(route);
        };
        practiceProvider.onPracticeCompletionConfirmed = () {
          tour.handlePracticeCompletionConfirmed();
        };

        tour.initForUser(userId: user.id, isNewRegistration: true).then((_) {
          if (mounted) {
            // First-run trigger for new users and backfill for existing users with 0 completed nodes
            final hasCompletedNodes = pathProvider.completedNodeIds.isNotEmpty;
            if (!hasCompletedNodes) {
              tour.checkAndStartTour();
            }
          }
        });
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

  void _showIncomingDuelDialog(Map<String, dynamic> request) {
    if (!mounted) return;
    showIncomingDuelInviteDialog(context, request);
  }

  void _setupNotificationTapListener() {
    _notificationSubscription = NotificationService.instance.notificationResponseStream.listen((payload) async {
      if (payload == null || !mounted) return;
      try {
        final data = jsonDecode(payload);
        final String type = data['type'] ?? '';
        final String? fromUid = data['fromUid'] ?? data['from_uid'];
        final String? postId = (data['postId'] ?? data['post_id'])?.toString();
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
        } else if (type == 'duel_invite' && postId != null && postId.isNotEmpty) {
          final request = await SupabaseService.instance.getDuelRequest(postId);
          if (!mounted) return;
          if (request != null && request['status'] == 'pending') {
            _showIncomingDuelDialog(request);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This challenge has expired or already been handled.'),
              ),
            );
          }
        } else if (type == 'pr_request' ||
            type == 'pr_accepted' ||
            type == 'solved') {
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

  Future<bool?> _showExitConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: DsCard(
            padding: const EdgeInsets.all(20),
            borderColor: Ds.border,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Glitch(size: 40, mood: GlitchMood.idle),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Leave DevSpace?',
                        style: DsText.h3.copyWith(fontSize: 18, color: Ds.bone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to exit the app?',
                  style: DsText.bodySm.copyWith(color: Ds.muted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: Ds.muted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Exit',
                          style: DsText.label.copyWith(color: Ds.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: DsButton(
                          label: 'Stay',
                          kind: DsButtonKind.aura,
                          height: 48,
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserOrNull;
    final unreadCount = context.select<NotificationsProvider, int>((p) => p.unreadCount);

    final initials = user?.initials ?? 'U';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // 1. If tour is active, tour handles back itself
        final tour = context.read<TourController>();
        if (tour.status == TourStatus.inProgress && tour.currentStep != null) {
          return;
        }

        // 2. If on Path, Ranks, Community or Profile (index != 0), switch to Play first
        if (widget.shell.currentIndex != 0) {
          widget.shell.goBranch(0);
          return;
        }

        // 3. On Play tab: show "Leave DevSpace?" dialog
        final shouldExit = await _showExitConfirmDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: TourHost(
        child: Scaffold(
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
        ),
      ),
    );
  }
}

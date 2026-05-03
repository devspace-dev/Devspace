import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/posts_provider.dart';
import 'providers/questions_provider.dart';
import 'providers/users_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/engagement_provider.dart';
import 'screens/home_screen.dart';
import 'screens/people_screen.dart';
import 'screens/qa_screen.dart';
import 'screens/aura_board_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/daily_challenge_screen.dart';
import 'screens/opportunities_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/weekly_challenge_pricing_screen.dart';
import 'screens/weekly_challenge_screen.dart';
import 'screens/weekly_free_challenge_screen.dart';
import 'screens/question_detail_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/messages_provider.dart';
import 'models/user_model.dart';
import 'services/notification_service.dart';
import 'models/conversation_model.dart';
import 'screens/chat_detail_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/glass_container.dart';
import 'providers/premium_provider.dart';
import 'models/notification_model.dart';
import 'widgets/tier_up_dialog.dart';
import 'utils/devspace_ui_helper.dart';
import 'screens/tier_up_celebration_screen.dart';
// Calling feature deferred to future update

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

class DevSpaceApp extends StatefulWidget {
  const DevSpaceApp({super.key});

  @override
  State<DevSpaceApp> createState() => _DevSpaceAppState();
}

class CupFab extends StatefulWidget {
  final VoidCallback onDaily;
  final VoidCallback onWeekly;

  const CupFab({
    super.key,
    required this.onDaily,
    required this.onWeekly,
  });

  @override
  State<CupFab> createState() => _CupFabState();
}

class _CupFabState extends State<CupFab> {
  bool _open = false;

  void _toggle() {
    setState(() => _open = !_open);
  }

  void _fireAction(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          width: 58,
          height: _open ? 116 : 0,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.bg2For(context).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: _open
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _CupOption(
                  icon: Icons.today_rounded,
                  visible: _open,
                  onTap: () => _fireAction(widget.onDaily),
                ),
                const SizedBox(height: 8),
                _CupOption(
                  icon: Icons.code_rounded,
                  visible: _open,
                  onTap: () => _fireAction(widget.onWeekly),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _toggle,
          child: AnimatedRotation(
            turns: _open ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CupOption extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool visible;

  const _CupOption({
    required this.icon,
    required this.onTap,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: Transform.translate(
        offset: Offset(0, visible ? 0 : 10),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: visible ? onTap : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bg2For(context),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevSpaceAppState extends State<DevSpaceApp> {
  int _tab = 0;
  bool _isUIVisible = true;
  late final PageController _pageController;
  StreamSubscription<String?>? _notificationSubscription;

  static const List<String> _titles = [
    'DevSpace',
    'Developers',
    'Q & A',
    'Opportunities',
    'Profile',
    'Aura Board',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initProviders();
    _setupNotificationTapListener();
  }

  void _setupNotificationTapListener() {
    _notificationSubscription = NotificationService.instance.notificationResponseStream.listen((payload) {
      if (payload == null || !mounted) return;
      try {
        final data = jsonDecode(payload);
        final String type = data['type'] ?? '';
        final String? postId = data['postId'];
        final String? questionId = data['questionId'];
        final String? fromUid = data['fromUid'];

        if (type == 'message' && fromUid != null) {
          final me = context.read<AuthProvider>().currentUserOrNull;
          if (me == null) return;
          
          final msgP = context.read<MessagesProvider>();
          final conv = msgP.conversations.firstWhere(
            (c) => c.participants.contains(fromUid),
            orElse: () => ConversationModel(
              id: '', // Temporary ID, will be resolved by getOrCreate
              participants: [me.id, fromUid],
              createdAt: DateTime.now(),
            ),
          );
          
          final other = context.read<UsersProvider>().getUserById(fromUid);
          if (other != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  conversation: conv,
                  otherUser: other,
                ),
              ),
            );
          }
        } else if (type == 'like' || type == 'comment') {
           // We navigate to profile for now since PostDetail is new
           if (fromUid != null) {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (_) => ProfileScreen(userId: fromUid)),
             );
           }
        } else if (type == 'pr_request' || type == 'solved') {
          if (questionId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QuestionDetailScreen(questionId: questionId)),
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to handle notification tap: $e');
      }
    });
  }

  Future<void> _initProviders() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      
      // Initialize shared public data
      context.read<UsersProvider>().fetchUsers();
      context.read<PostsProvider>().fetchFeed();
      context.read<QuestionsProvider>().fetchQuestions();

      // Listen for auth changes to init user-specific services
      auth.addListener(_onAuthChanged);
      _onAuthChanged(); // Run once for initial state
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUserOrNull;

    if (user != null) {
      try {
        NotificationService.instance.init(user.id);
        
        final notificationsProvider = context.read<NotificationsProvider>();
        notificationsProvider.init(user.id);
        
        // Listen for tier_up notifications to show the full-screen dialog
        notificationsProvider.addListener(() {
          final tierUp = notificationsProvider.notifications.firstWhere(
            (n) => !n.read && n.type == 'tier_up',
            orElse: () => NotificationModel(id: '', toUid: '', fromUid: '', type: '', message: '', createdAt: DateTime.now(), read: false),
          );
          
          if (tierUp.id.isNotEmpty) {
            // Mark as read immediately so we don't show it twice
            notificationsProvider.markAsRead(tierUp.id);
            
            // Show the full-screen animation
            final tier = TierHelper.getTier(user.aura);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TierUpCelebrationScreen(
                  user: user,
                  tierName: tier.name,
                ),
              ),
            );
          }
        });

        context.read<MessagesProvider>().init(user.id);
        context.read<EngagementProvider>().fetchOverview();
        context.read<PremiumProvider>().loadUserPremiumStatus();
      } catch (e) {
        debugPrint('Provider initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }



  void _showNotifications(BuildContext context) {
    late final UserModel me;
    try {
      me = context.read<AuthProvider>().currentUser;
    } catch (_) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GlassContainer(
              color: AppColors.bgFor(context),
              opacity: 0.8,
              blur: 25,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                  top: BorderSide(color: AppColors.borderFor(context), width: 0.5)),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border2For(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                        letterSpacing: -0.8,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<NotificationsProvider>()
                            .markAllAsRead(me.id);
                        // Force a UI rebuild to reflect the changes
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<NotificationsProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }
                    if (provider.notifications.isEmpty) {
                      return Center(
                        child: Text(
                          'No new notifications',
                          style: TextStyle(color: AppColors.text3For(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: AppColors.borderFor(context)),
                      itemBuilder: (context, i) {
                        final n = provider.notifications[i];
                        return ListTile(
                          onTap: () async {
                            if (!n.read) provider.markAsRead(n.id);
                            
                            // Navigation logic for different types
                            if (n.questionId != null) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuestionDetailScreen(
                                    questionId: n.questionId!,
                                  ),
                                ),
                              );
                            } else if (n.postId != null) {
                              Navigator.pop(context);
                              // We don't have a PostDetailScreen yet, 
                              // so we navigate to the user profile where the post is.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: n.toUid),
                                ),
                              );
                            } else if (n.type == 'follow') {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileScreen(userId: n.fromUid),
                                ),
                              );
                            } else if (n.type == 'message') {
                              Navigator.pop(context);
                              final msgP = context.read<MessagesProvider>();
                              final conv = msgP.conversations.firstWhere(
                                (c) => c.participants.contains(n.fromUid),
                                orElse: () => ConversationModel(
                                  id: n.payload?['conversation_id'] ?? '',
                                  participants: [me.id, n.fromUid],
                                  createdAt: DateTime.now(),
                                ),
                              );
                              final other = context.read<UsersProvider>().getUserById(n.fromUid);
                              if (other != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      conversation: conv,
                                      otherUser: other,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: n.read
                                  ? AppColors.bg2For(context)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n.type == 'like'
                                  ? Icons.favorite_rounded
                                  : n.type == 'comment'
                                      ? Icons.comment_rounded
                                      : n.type == 'message'
                                          ? Icons.mail_outline_rounded
                                          : n.type == 'pr_request'
                                              ? Icons.call_merge_rounded
                                              : Icons.person_add_rounded,
                              size: 18,
                              color: n.read
                                  ? AppColors.text3For(context)
                                  : AppColors.primary,
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.message,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: n.read
                                      ? AppColors.text2For(context)
                                      : AppColors.textFor(context),
                                  fontWeight: n.read
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                              ),
                              if (n.type == 'pr_request' && !n.read)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            HapticFeedback.mediumImpact();
                                            final qp = context.read<QuestionsProvider>();
                                            await qp.fetchPullRequests(n.questionId!);
                                            final pr = qp.getMyPullRequest(n.questionId!, n.fromUid);
                                            if (pr != null) {
                                              await qp.updatePullRequestStatus(
                                                questionId: n.questionId!,
                                                prId: pr.id,
                                                status: 'accepted',
                                              );
                                              provider.markAsRead(n.id);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Accept',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            HapticFeedback.lightImpact();
                                            final qp = context.read<QuestionsProvider>();
                                            await qp.fetchPullRequests(n.questionId!);
                                            final pr = qp.getMyPullRequest(n.questionId!, n.fromUid);
                                            if (pr != null) {
                                              await qp.updatePullRequestStatus(
                                                questionId: n.questionId!,
                                                prId: pr.id,
                                                status: 'rejected',
                                              );
                                              provider.markAsRead(n.id);
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.text3For(context),
                                            side: BorderSide(color: AppColors.borderFor(context)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Decline',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            _formatTime(n.createdAt),
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.text3For(context)),
                          ),
                          trailing: !n.read
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (i * 20).ms);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _onTabSelected(int index) {
    if (index == _tab) {
      if (index == 0) {
        homeScreenKey.currentState?.scrollToTopAndRefresh();
      }
      return;
    }
    setState(() => _tab = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;
    final unreadMessages = context.watch<MessagesProvider>().totalUnreadCount;

    final List<Widget> screens = [
      HomeScreen(key: homeScreenKey),
      const PeopleScreen(),
      const QAScreen(),
      const OpportunitiesScreen(),
      const ProfileScreen(),
      const AuraBoardScreen(),
    ];

    final showFab = _tab < 4;
    final isHome = _tab == 0;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      extendBody: true,
      extendBodyBehindAppBar: false,
      floatingActionButton: AnimatedSlide(
        offset: _isUIVisible ? Offset.zero : const Offset(0, 3),
        duration: const Duration(milliseconds: 300),
        child: isHome
            ? CupFab(
                onDaily: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyChallengeScreen(),
                    ),
                  );
                },
                onWeekly: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WeeklyChallengePricingScreen(),
                    ),
                  );
                },
              )
            : (showFab
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyChallengeScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.white),
                  )
                : null),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GlassContainer(
          color: AppColors.bgFor(context),
          opacity: 0.7,
          blur: 20,
          borderRadius: BorderRadius.zero,
          border: Border(
              bottom:
                  BorderSide(color: AppColors.borderFor(context), width: 0.5)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleSpacing: 20,
            title: _tab == 0
                ? Text(
                    'DevSpace',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -1.5,
                      color: AppColors.textFor(context),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutBack,
                    )
                : Text(
                    _titles[_tab],
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: AppColors.textFor(context),
                    ),
                  ),
            actions: [
              IconButton(
                onPressed: () => _showNotifications(context),
                icon: Badge(
                  backgroundColor: AppColors.primary,
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.notifications_none_rounded, size: 24),
                ),
              ),
              if (me != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _onTabSelected(5), // Navigate to Aura Board
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${me.aura}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  );
                },
                icon: Badge(
                  backgroundColor: AppColors.primary,
                  isLabelVisible: unreadMessages > 0,
                  label: Text('$unreadMessages',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.mail_outline_rounded, size: 24),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!_isUIVisible) setState(() => _isUIVisible = true);
          } else if (notification.direction == ScrollDirection.reverse) {
            if (_isUIVisible) setState(() => _isUIVisible = false);
          }
          return false;
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_tab != 0) {
              _onTabSelected(0); // Go back to Home tab
            } else {
              // If on home tab, we might want to allow popping if there's no other way
              // But usually we want to exit the app or something.
              // In Flutter, if we return true from onWillPop it closes.
              // With PopScope(canPop: false), we need to manually pop if we want to.
              final NavigatorState navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                // Exit app
                SystemNavigator.pop();
              }
            }
          },
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (_tab != index && mounted) {
                setState(() => _tab = index);
              }
            },
            children: screens,
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _isUIVisible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        child: DevSpaceBottomNav(
          currentIndex: _tab,
          onTap: _onTabSelected,
          unreadNotifications: unreadCount,
          unreadMessages: unreadMessages,
        ),
      ),
    );
  }
}

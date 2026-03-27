import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/posts_provider.dart';
import 'providers/questions_provider.dart';
import 'providers/users_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/home_screen.dart';
import 'screens/people_screen.dart';
import 'screens/qa_screen.dart';
import 'screens/aura_board_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/auth_provider.dart';
import 'models/user_model.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/glass_container.dart';

class DevSpaceApp extends StatefulWidget {
  const DevSpaceApp({super.key});

  @override
  State<DevSpaceApp> createState() => _DevSpaceAppState();
}

class _DevSpaceAppState extends State<DevSpaceApp> {
  int _tab = 0;

  static const List<String> _titles = [
    'DevSpace',
    'Developers',
    'Q & A',
    'Aura Board',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<UsersProvider>().fetchUsers();
      context.read<PostsProvider>().fetchFeed();
      try {
        context.read<QuestionsProvider>().fetchQuestions();
        context.read<NotificationsProvider>().init(auth.currentUser.id);
      } catch (_) {/* no user yet */}
    });
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
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GlassContainer(
          color: AppColors.bg,
          opacity: 0.95,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.6,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<NotificationsProvider>()
                            .markAllAsRead(me.id);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<NotificationsProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 48, color: AppColors.text4),
                            const SizedBox(height: 16),
                            const Text(
                              'All caught up!',
                              style: TextStyle(color: AppColors.text3, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final n = provider.notifications[i];
                        final color = n.read ? AppColors.text3 : AppColors.primary;
                        return ListTile(
                          onTap: () {
                            if (!n.read) provider.markAsRead(n.id);
                          },
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n.type == 'like'
                                  ? Icons.favorite_rounded
                                  : n.type == 'comment'
                                      ? Icons.comment_rounded
                                      : Icons.person_add_rounded,
                              size: 20,
                              color: color,
                            ),
                          ),
                          title: Text(
                            n.message,
                            style: TextStyle(
                              fontSize: 15,
                              color: n.read ? AppColors.text2 : AppColors.text,
                              fontWeight:
                                  n.read ? FontWeight.w500 : FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.text4, fontWeight: FontWeight.w700),
                          ),
                          trailing: !n.read
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ).animate().fadeIn(delay: (i * 30).ms).slideX(begin: 0.1, end: 0);
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;
    final topPadding = MediaQuery.of(context).padding.top;

    final List<Widget> screens = [
      const HomeScreen(),
      const PeopleScreen(),
      const QAScreen(),
      const AuraBoardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + topPadding),
        child: GlassContainer(
          color: AppColors.bg,
          opacity: 0.85,
          blur: 20,
          borderRadius: BorderRadius.zero,
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 2)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            primary: true,
            title: _tab == 0
                ? Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.tropicalGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text('⌥',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900))),
                    ),
                    const SizedBox(width: 12),
                    const Text('DevSpace',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: AppColors.text,
                            letterSpacing: -0.8)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text('BETA',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8)),
                    ),
                  ])
                : Text(_titles[_tab], style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.6)),
            actions: [
              IconButton(
                onPressed: () => _showNotifications(context),
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.notifications_none_rounded, size: 26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.yellow.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          '${me?.aura ?? 0}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.yellow),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: DevSpaceBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

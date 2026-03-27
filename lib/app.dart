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
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => GlassContainer(
          color: AppColors.bg,
          opacity: 0.8,
          blur: 25,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.8,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<NotificationsProvider>()
                            .markAllAsRead(me.id);
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
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }
                    if (provider.notifications.isEmpty) {
                      return const Center(
                        child: Text(
                          'No new notifications',
                          style: TextStyle(color: AppColors.text3),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final n = provider.notifications[i];
                        return ListTile(
                          onTap: () {
                            if (!n.read) provider.markAsRead(n.id);
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: n.read
                                  ? AppColors.bg2
                                  : AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              n.type == 'like'
                                  ? Icons.favorite_rounded
                                  : n.type == 'comment'
                                      ? Icons.comment_rounded
                                      : Icons.person_add_rounded,
                              size: 18,
                              color:
                                  n.read ? AppColors.text3 : AppColors.primary,
                            ),
                          ),
                          title: Text(
                            n.message,
                            style: TextStyle(
                              fontSize: 15,
                              color: n.read ? AppColors.text2 : AppColors.text,
                              fontWeight:
                                  n.read ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text3),
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
                        ).animate().fadeIn(duration: 300.ms, delay: (i * 20).ms);
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

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;

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
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GlassContainer(
          color: AppColors.bg,
          opacity: 0.7,
          blur: 20,
          borderRadius: BorderRadius.zero,
          border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _tab == 0
                ? const Text(
                    'DevSpace',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.8,
                      color: AppColors.text,
                    ),
                  )
                : Text(_titles[_tab]),
            actions: [
              IconButton(
                onPressed: () => _showNotifications(context),
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              if (me != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            '${me.aura}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          opacity: 0.9,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
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
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.notifications.isEmpty) {
                      return const Center(
                        child: Text(
                          'No notifications yet',
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
                            // Navigate if needed
                          },
                          leading: CircleAvatar(
                            backgroundColor: n.read
                                ? AppColors.bg2
                                : AppColors.primary.withValues(alpha: 0.1),
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
                              fontSize: 14,
                              color: n.read ? AppColors.text2 : AppColors.text,
                              fontWeight:
                                  n.read ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(n.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.text3),
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
                        );
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
          opacity: 0.8,
          blur: 15,
          border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5)),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _tab == 0
                ? Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                          child: Text('⌥',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white))),
                    ),
                    const SizedBox(width: 10),
                    const Text('DevSpace',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.text,
                            letterSpacing: -0.4)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('BETA',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppColors.text4,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6)),
                    ),
                  ])
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
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            '${me?.aura ?? 0}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text2),
                          ),
                        ],
                      ),
                    ),
                  ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/posts_provider.dart';
import 'providers/users_provider.dart';
import 'screens/home_screen.dart';
import 'screens/people_screen.dart';
import 'screens/qa_screen.dart';
import 'screens/aura_board_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/auth_provider.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav.dart';

class DevSpaceApp extends StatefulWidget {
  const DevSpaceApp({super.key});

  @override
  State<DevSpaceApp> createState() => _DevSpaceAppState();
}

class _DevSpaceAppState extends State<DevSpaceApp> {
  int _tab = 0;

  static const List<String> _titles = [
    'DevSpace', 'Developers', 'Q & A', 'Aura Board', 'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsersProvider>().fetchUsers();
      context.read<PostsProvider>().fetchFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    final List<Widget> screens = [
      const HomeScreen(),
      const PeopleScreen(),
      const QAScreen(),
      const AuraBoardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: _tab == 0
            ? Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: Text('⌥', style: TextStyle(fontSize: 15))),
                ),
                const SizedBox(width: 8),
                const Text('DevSpace',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 19,
                      color: AppColors.text, letterSpacing: -0.5)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('BETA',
                      style: TextStyle(fontSize: 9, color: AppColors.text3,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ])
            : Text(_titles[_tab]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '⚡ ${me.aura}',
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: DevSpaceBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

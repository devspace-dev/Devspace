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
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(child: Text('⌥', style: TextStyle(fontSize: 14, color: Colors.white))),
                ),
                const SizedBox(width: 10),
                const Text('DevSpace',
                    style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18,
                      color: AppColors.text, letterSpacing: -0.4)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('BETA',
                      style: TextStyle(fontSize: 9, color: AppColors.text4,
                          fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                ),
              ])
            : Text(_titles[_tab]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        '${me.aura}',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/founder_tools_screen.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final posts = context.watch<PostsProvider>().postsForUser(me.id);
    final totalLikes = posts.fold<int>(0, (sum, post) => sum + post.likes);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(context),
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _AccountCard(userName: me.name, handle: me.handle, email: me.email),
          const SizedBox(height: 16),
          _AnalyticsCard(
            postsCount: posts.length,
            totalLikes: totalLikes,
            aura: me.aura,
          ),
          const _SectionHeader(title: 'APPEARANCE'),
          const _ThemeSelector(),
          const _SectionHeader(title: 'PROFILE'),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            subtitle: 'Update your builder identity and public details.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileSetupScreen(mode: ProfileSetupMode.edit),
                ),
              );
            },
          ),
          const _SectionHeader(title: 'SAVED'),
          _SettingsTile(
            icon: Icons.bookmark_outline_rounded,
            title: 'Saved posts',
            subtitle: 'Revisit every post you bookmarked.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavedPostsScreen(),
                ),
              );
            },
          ),
          const _SectionHeader(title: 'APP'),
          _SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Founder tools',
            subtitle: 'Seed events and challenge templates for the community.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FounderToolsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About DevSpace',
            subtitle: 'Why this app exists and what it is built for.',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _handleLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.35),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Sign out',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
        title: Text(
          'Sign out?',
          style: TextStyle(color: AppColors.textFor(context)),
        ),
        content: Text(
          'You will return to the login screen on this device.',
          style: TextStyle(color: AppColors.text2For(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.bg2For(context),
          title: Text(
            'About DevSpace',
            style: TextStyle(color: AppColors.textFor(context)),
          ),
          content: Text(
            'DevSpace is built for student developers to share progress, ask for help, and build a real builder identity inside their college community.',
            style: TextStyle(color: AppColors.text2For(context), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.text4For(context),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          _ThemeOption(
            label: 'System',
            icon: Icons.brightness_auto_rounded,
            isSelected: themeProvider.themeMode == ThemeMode.system,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),
          _ThemeOption(
            label: 'Light',
            icon: Icons.light_mode_rounded,
            isSelected: themeProvider.themeMode == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),
          _ThemeOption(
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            isSelected: themeProvider.themeMode == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bg3For(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.text3For(context),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textFor(context)
                      : AppColors.text3For(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bg3For(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.text2For(context), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textFor(context),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: AppColors.text3For(context),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.text4For(context),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String userName;
  final String handle;
  final String email;

  const _AccountCard({
    required this.userName,
    required this.handle,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(
              color: AppColors.text4For(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: TextStyle(
              color: AppColors.textFor(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@$handle',
            style: TextStyle(
              color: AppColors.text3For(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg3For(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: AppColors.text3For(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      color: AppColors.text2For(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final int postsCount;
  final int totalLikes;
  final int aura;

  const _AnalyticsCard({
    required this.postsCount,
    required this.totalLikes,
    required this.aura,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InsightItem(
            label: 'Posts',
            value: '$postsCount',
            icon: Icons.grid_view_rounded,
          ),
          _InsightItem(
            label: 'Likes',
            value: '$totalLikes',
            icon: Icons.favorite_rounded,
          ),
          _InsightItem(
            label: 'Aura',
            value: '$aura',
            icon: Icons.auto_awesome_rounded,
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.text3For(context)),
        ),
      ],
    );
  }
}

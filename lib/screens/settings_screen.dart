import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final posts = context.watch<PostsProvider>().postsForUser(me.id);
    final totalLikes = posts.fold<int>(0, (sum, p) => sum + p.likes);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'ANALYTICS & INSIGHTS'),
          _AnalyticsCard(
            postsCount: posts.length,
            totalLikes: totalLikes,
            aura: me.aura,
          ),
          const _SectionHeader(title: 'ACCOUNT'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile Information',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          const _SectionHeader(title: 'SUPPORT'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About DevSpace',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
              ),
              child: const Text('Log Out',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Log Out?', style: TextStyle(color: AppColors.text)),
        content: const Text('Are you sure you want to log out of DevSpace?',
            style: TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.text4,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text2, size: 22),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text4),
      onTap: onTap,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bg2,
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InsightItem(
                  label: 'Posts', value: '$postsCount', icon: Icons.grid_view_rounded),
              _InsightItem(
                  label: 'Likes', value: '$totalLikes', icon: Icons.favorite_rounded),
              _InsightItem(
                  label: 'Aura', value: '$aura', icon: Icons.auto_awesome_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text(
                'Your engagement is up 12% this week',
                style: TextStyle(color: AppColors.text3, fontSize: 12),
              ),
            ],
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
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      ],
    );
  }
}

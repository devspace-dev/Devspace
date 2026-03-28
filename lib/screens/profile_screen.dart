import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../screens/connections_screen.dart';
import '../screens/founder_tools_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/aura_bar.dart';
import '../widgets/github_card.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final usersP = context.watch<UsersProvider>();
    final postsP = context.watch<PostsProvider>();
    final isMe = userId == null || userId == me.id;
    final user = isMe ? me : usersP.getUserById(userId!);

    if (!isMe && user == null && usersP.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        body: const AppLoadingState(
          title: 'Loading profile',
          message: 'Fetching this builder profile from DevSpace.',
        ),
      );
    }

    if (!isMe && user == null && usersP.error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(backgroundColor: AppColors.bgFor(context)),
        body: AppErrorState(
          title: 'Profile unavailable',
          message: usersP.error!,
          actionLabel: 'Retry',
          onAction: usersP.refreshUsers,
        ),
      );
    }

    if (!isMe && user == null) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(backgroundColor: AppColors.bgFor(context)),
        body: AppEmptyState(
          icon: Icons.person_search_rounded,
          title: 'Profile unavailable',
          message: 'We could not find this student profile.',
          actionLabel: 'Refresh',
          onAction: usersP.refreshUsers,
        ),
      );
    }

    final profileUser = user ?? me;
    final posts = postsP.postsForUser(profileUser.id);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bgFor(context).withValues(alpha: 0.92),
            leading: userId != null
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textFor(context),
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              profileUser.name,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textFor(context),
              ),
            ),
            actions: [
              if (isMe)
                Row(
                  children: [
                    if (profileUser.isAdmin || profileUser.isFounder)
                      IconButton(
                        tooltip: 'Founder Tools',
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FounderToolsScreen(),
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupScreen(
                            mode: ProfileSetupMode.edit,
                          ),
                        ),
                      ),
                      icon: Icon(
                        profileUser.profileCompleted
                            ? Icons.edit_rounded
                            : Icons.auto_fix_high_rounded,
                        size: 16,
                      ),
                      label: Text(
                        profileUser.profileCompleted ? 'Edit' : 'Finish',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: Icon(
                        Icons.settings_outlined,
                        color: AppColors.textFor(context),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: usersP.isFollowUpdating(profileUser.id)
                        ? null
                        : () async {
                            await usersP.toggleFollow(me.id, profileUser.id);
                            if (!context.mounted) return;

                            final error = usersP.followError(profileUser.id);
                            if (error == null) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: profileUser.isFollowing
                            ? Colors.transparent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: profileUser.isFollowing
                              ? AppColors.border2For(context)
                              : Colors.white,
                        ),
                      ),
                      child: Text(
                        usersP.isFollowUpdating(profileUser.id)
                            ? 'Saving...'
                            : (profileUser.isFollowing ? 'Following' : 'Follow'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: profileUser.isFollowing
                              ? AppColors.textFor(context)
                              : AppColors.bgFor(context),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bg2For(context),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.bgFor(context),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: profileUser.color.withValues(alpha: 0.18),
                                    blurRadius: 22,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: UserAvatar(
                                user: profileUser,
                                size: 78,
                                showStory: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileUser.name,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textFor(context),
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${profileUser.handle}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.text3For(context),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _MetaChip(label: profileUser.role),
                                      if (profileUser.year.isNotEmpty ||
                                          profileUser.branch.isNotEmpty)
                                        _MetaChip(label: profileUser.academicLabel),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          profileUser.bio.isEmpty
                              ? 'This student has not added a bio yet.'
                              : profileUser.bio,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text2For(context),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _StatButton(
                                count: profileUser.followers,
                                label: 'Followers',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ConnectionsScreen(
                                      user: profileUser,
                                      type: ConnectionListType.followers,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatButton(
                                count: posts.length,
                                label: 'Posts',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatButton(
                                count: profileUser.following,
                                label: 'Following',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ConnectionsScreen(
                                      user: profileUser,
                                      type: ConnectionListType.following,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 14),
                  if (isMe && !profileUser.profileCompleted)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete your builder profile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your branch, stack, and what you are building so students can discover you properly.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text2,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileSetupScreen(
                                  mode: ProfileSetupMode.onboarding,
                                ),
                              ),
                            ),
                            child: const Text('Complete profile'),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bg2For(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Builder details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textFor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (profileUser.academicLabel.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: profileUser.academicLabel,
                          ),
                        _InfoRow(
                          icon: Icons.construction_rounded,
                          label: profileUser.building,
                        ),
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: profileUser.college,
                          isLast: true,
                        ),
                        if (profileUser.stack.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Stack',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text3For(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profileUser.stack
                                .map<Widget>(
                                  (stackItem) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgFor(context),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.borderFor(context),
                                      ),
                                    ),
                                    child: Text(
                                      stackItem,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text2For(context),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 140.ms, duration: 320.ms),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bg3For(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderFor(context)),
                    ),
                    child: AuraBar(aura: profileUser.aura),
                  ).animate().fadeIn(delay: 220.ms, duration: 320.ms).slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  GitHubCard(githubHandle: profileUser.githubHandle)
                      .animate()
                      .fadeIn(delay: 260.ms, duration: 320.ms),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(color: AppColors.border, height: 1),
          ),
          postsP.isLoading && postsP.posts.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: AppLoadingState(
                      title: 'Loading posts',
                      message: 'Fetching recent updates from this builder.',
                    ),
                  ),
                )
              : postsP.feedError != null && postsP.posts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: AppErrorState(
                          title: 'Posts unavailable',
                          message: postsP.feedError!,
                          actionLabel: 'Retry',
                          onAction: postsP.refreshFeed,
                        ),
                      ),
                    )
                  : posts.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No posts yet',
                                style: TextStyle(
                                  color: AppColors.text3,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => PostCard(post: posts[i]),
                            childCount: posts.length,
                          ),
                        ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.text2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.borderFor(context).withValues(alpha: 0.6),
                ),
                ),
              ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text2For(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatButton extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatButton({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.bgFor(context),
            border: Border.all(
              color: AppColors.borderFor(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textFor(context),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text3For(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

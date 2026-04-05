import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../screens/chat_detail_screen.dart';
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
    final me = context.watch<AuthProvider>().currentUserOrNull;
    if (me == null) {
      return Scaffold(backgroundColor: AppColors.bgFor(context));
    }

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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bgFor(context).withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textFor(context),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              profileUser.handle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textFor(context),
              ),
            ),
            actions: [
              if (isMe)
                Row(
                  children: [
                    if (profileUser.isAdmin || profileUser.isFounder)
                      _HeaderAction(
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FounderToolsScreen(
                                mode: FounderToolsMode.founderTools,
                              ),
                            ),
                          );
                        },
                      ),
                    _HeaderAction(
                      icon: Icons.settings_outlined,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              else
                Row(
                  children: [
                    _HeaderAction(
                      icon: Icons.mail_outline_rounded,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final provider = context.read<MessagesProvider>();
                        try {
                          final conv = await provider.startConversation(
                            me.id,
                            profileUser.id,
                          );
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversation: conv,
                                otherUser: profileUser,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString()),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        user: profileUser,
                        size: 86,
                        showRing: true,
                        showStory: true,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  profileUser.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textFor(context),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (profileUser.isFounder) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded,
                                      color: Colors.amber, size: 20),
                                ],
                              ],
                            ),
                            Text(
                              '@${profileUser.handle}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text3For(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isMe)
                              _EditButton(onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileSetupScreen(
                                      mode: ProfileSetupMode.edit,
                                    ),
                                  ),
                                );
                              })
                            else
                              _FollowButton(
                                isFollowing: profileUser.isFollowing,
                                isUpdating:
                                    usersP.isFollowUpdating(profileUser.id),
                                onTap: () async {
                                  HapticFeedback.mediumImpact();
                                  await usersP.toggleFollow(
                                      me.id, profileUser.id);
                                  if (!context.mounted) return;
                                  final error =
                                      usersP.followError(profileUser.id);
                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(error),
                                          behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profileUser.bio.isEmpty
                        ? 'Student builder on DevSpace.'
                        : profileUser.bio,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.text2For(context),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          count: posts.length,
                          label: 'Posts',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
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
                  const SizedBox(height: 24),
                  if (profileUser.stack.isNotEmpty) ...[
                    Text(
                      'Tech Stack',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: profileUser.stack
                          .map((s) => _SkillChip(label: s))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bg2For(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.borderFor(context)
                              .withValues(alpha: 0.5)),
                    ),
                    child: AuraBar(aura: profileUser.aura),
                  ),
                  const SizedBox(height: 16),
                  GitHubCard(githubHandle: profileUser.githubHandle),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Builds',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.text4For(context), size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'No builds shared yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.text3For(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => PostCard(post: posts[i])
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (i * 50).ms),
                childCount: posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textFor(context).withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textFor(context)),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback? onTap;

  const _StatBox({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.borderFor(context).withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text3For(context),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isUpdating;
  final VoidCallback onTap;

  const _FollowButton(
      {required this.isFollowing,
      required this.isUpdating,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUpdating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : AppColors.primary,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color:
                isFollowing ? AppColors.borderFor(context) : AppColors.primary,
            width: 1.2,
          ),
        ),
        child: Text(
          isUpdating ? '...' : (isFollowing ? 'Following' : 'Follow'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isFollowing ? AppColors.textFor(context) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        side: BorderSide(color: AppColors.borderFor(context), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        'Edit Profile',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColors.textFor(context),
        ),
      ),
    );
  }
}

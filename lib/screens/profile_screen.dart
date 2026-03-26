import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../providers/posts_provider.dart';
import '../screens/profile_setup_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../widgets/aura_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/github_card.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId; // null = current user

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final me      = context.watch<AuthProvider>().currentUser;
    final usersP  = context.watch<UsersProvider>();
    final postsP  = context.watch<PostsProvider>();
    final isMe    = userId == null || userId == me.id;
    final user    = isMe ? me : (usersP.getUserById(userId!) ?? me);
    final posts   = postsP.postsForUser(user.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar with back button
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg.withValues(alpha: 0.9),
            leading: userId != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text)),
            actions: [
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSetupScreen(
                          mode: ProfileSetupMode.edit,
                        ),
                      ),
                    ),
                    icon: Icon(
                      user.profileCompleted
                          ? Icons.edit_rounded
                          : Icons.auto_fix_high_rounded,
                      size: 16,
                    ),
                    label: Text(
                      user.profileCompleted ? 'Edit' : 'Finish',
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: usersP.isFollowUpdating(user.id)
                        ? null
                        : () async {
                            await usersP.toggleFollow(me.id, user.id);
                            if (!context.mounted) return;

                            final error = usersP.followError(user.id);
                            if (error == null) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: user.isFollowing ? Colors.transparent : Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: user.isFollowing ? AppColors.border2 : Colors.white),
                      ),
                      child: Text(
                        usersP.isFollowUpdating(user.id)
                            ? 'Saving...'
                            : (user.isFollowing ? 'Following' : 'Follow'),
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: user.isFollowing ? AppColors.text : AppColors.bg,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Banner
          SliverToBoxAdapter(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [user.color.withValues(alpha: 0.3), AppColors.bg2],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Avatar + info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 4),
                      ),
                      child: UserAvatar(user: user, size: 76, showStory: true),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: AppColors.text, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text('@${user.handle}',
                            style: const TextStyle(fontSize: 14, color: AppColors.text3)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(label: user.role),
                            if (user.year.isNotEmpty || user.branch.isNotEmpty)
                              _MetaChip(label: user.academicLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio.isEmpty
                              ? 'This student has not added a bio yet.'
                              : user.bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.text2,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isMe && !user.profileCompleted)
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
                        Wrap(
                          spacing: 16, runSpacing: 4,
                          children: [
                            if (user.academicLabel.isNotEmpty)
                              _InfoChip(icon: '📍', label: user.academicLabel),
                            _InfoChip(icon: '🛠', label: user.building),
                            _InfoChip(icon: '🎓', label: user.college),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: user.stack.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Aura card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: AuraBar(aura: user.aura),
                        ),
                        const SizedBox(height: 14),

                        // Stats row
                        Row(
                          children: [
                            _Stat(count: user.followers, label: 'followers'),
                            const SizedBox(width: 20),
                            _Stat(count: user.following, label: 'following'),
                            const SizedBox(width: 20),
                            _Stat(count: posts.length, label: 'posts'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // GitHub activity card
                        GitHubCard(githubHandle: user.githubHandle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: AppColors.border, height: 1)),

          // Posts
          posts.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No posts yet',
                          style: TextStyle(color: AppColors.text3, fontSize: 14))),
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
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
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

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text4)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;
  const _Stat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$count ',
            style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../providers/posts_provider.dart';
import '../screens/profile_setup_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/user_avatar.dart';
import '../widgets/aura_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/github_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // null = current user

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingCover = false;

  Future<void> _updateCover(String userId) async {
    final file = await StorageService.instance.pickImage();
    if (file == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final url = await StorageService.instance.uploadCoverPhoto(userId, file);
      await SupabaseService.instance.updateUser(userId, {'cover_url': url});
      if (mounted) {
        context.read<UsersProvider>().refreshUsers();
        await AuthService.instance.refreshCurrentUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cover: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final usersP = context.watch<UsersProvider>();
    final postsP = context.watch<PostsProvider>();
    final isMe = widget.userId == null || widget.userId == me.id;
    final user = isMe ? me : usersP.getUserById(widget.userId!);

    if (!isMe && user == null && usersP.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: AppLoadingState(
          title: 'Loading profile',
          message: 'Fetching this builder profile from DevSpace.',
        ),
      );
    }

    if (!isMe && user == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.bg),
        body: AppEmptyState(
          icon: Icons.person_search_rounded,
          title: 'Profile unavailable',
          message: 'We could not find this student profile.',
          actionLabel: 'Refresh',
          onAction: () => usersP.refreshUsers(),
        ),
      );
    }

    final profileUser = user ?? me;
    final posts = postsP.postsForUser(profileUser.id);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: widget.userId != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (profileUser.coverUrl.isNotEmpty)
                    Image.network(profileUser.coverUrl, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.bg2],
                        ),
                      ),
                    ),
                  // Overlay for better visibility of back button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  if (isMe)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _isUploadingCover ? null : () => _updateCover(profileUser.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _isUploadingCover
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
            ],
          ),

          // Avatar + info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 4),
                          ),
                          child: UserAvatar(user: profileUser, size: 80, showStory: true),
                        ),
                      ),
                      const Spacer(),
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileSetupScreen(
                                  mode: ProfileSetupMode.edit,
                                ),
                              ),
                            ),
                            child: const Text('Edit Profile'),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FollowButton(fromUid: me.id, toUid: profileUser.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(profileUser.name,
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: AppColors.text, letterSpacing: -0.5)),
                          const SizedBox(width: 8),
                          AuraPill(aura: profileUser.aura),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('@${profileUser.handle}',
                          style: const TextStyle(fontSize: 14, color: AppColors.text3)),
                      const SizedBox(height: 12),
                      if (profileUser.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            profileUser.bio,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text2,
                              height: 1.5,
                            ),
                          ),
                        ),
                      
                      Wrap(
                        spacing: 16, runSpacing: 8,
                        children: [
                          if (profileUser.academicLabel.isNotEmpty)
                            _InfoChip(icon: '📍', label: profileUser.academicLabel),
                          _InfoChip(icon: '🛠', label: profileUser.building),
                          _InfoChip(icon: '🎓', label: profileUser.college),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: profileUser.stack
                            .map<Widget>(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          _Stat(count: profileUser.followers, label: 'followers'),
                          const SizedBox(width: 20),
                          _Stat(count: profileUser.following, label: 'following'),
                          const SizedBox(width: 20),
                          _Stat(count: posts.length, label: 'posts'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // GitHub activity card
                      GitHubCard(githubHandle: profileUser.githubHandle),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: AppColors.border, height: 1)),

          // Posts
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
                      onAction: () {
                        postsP.refreshFeed();
                      },
                    ),
                  ),
                )
              : posts.isEmpty
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

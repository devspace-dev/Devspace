import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../models/badge_model.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import 'aura_pill.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showComments = false;
  final _commentCtrl = TextEditingController();
  final List<Map<String, String>> _localComments = [];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsP = context.watch<PostsProvider>();
    final post   = postsP.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);
    final usersP = context.read<UsersProvider>();
    final me     = context.read<AuthProvider>().currentUser;
    final user   = usersP.getUserById(post.userId) ?? me;
    final badge  = getBadge(user.aura);
    final lines  = post.content.split('\n').where((l) => l.isNotEmpty).toList();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + thread line
          Column(
            children: [
              UserAvatar(user: user, size: 44, showRing: true),
              if (_showComments)
                Container(
                  width: 2, height: 60,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
                    Text('@${user.handle}',
                        style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                    Text('·', style: const TextStyle(fontSize: 12, color: AppColors.border2)),
                    Text(timeago.format(post.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                    AuraPill(aura: user.aura, small: true),
                  ],
                ),
                const SizedBox(height: 3),

                // Building status
                Row(
                  children: [
                    const Text('🛠 ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(user.building,
                          style: const TextStyle(fontSize: 11, color: AppColors.text4),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Post content
                ...lines.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 15,
                      color: e.key == 0 ? AppColors.text : AppColors.text2,
                      height: 1.6,
                    ),
                  ),
                )),
                const SizedBox(height: 10),

                // Tags
                if (post.tags.isNotEmpty)
                  Wrap(
                    spacing: 10,
                    children: post.tags.map((t) => Text(
                      '#$t',
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    )).toList(),
                  ),
                const SizedBox(height: 10),

                // Action bar
                Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      count: post.comments + _localComments.length,
                      active: _showComments,
                      activeColor: AppColors.primary,
                      onTap: () => setState(() => _showComments = !_showComments),
                    ),
                    _ActionBtn(
                      icon: Icons.repeat_rounded,
                      activeIcon: Icons.repeat_rounded,
                      count: post.reposts,
                      active: post.isReposted,
                      activeColor: AppColors.repost,
                      onTap: () => context.read<PostsProvider>().toggleRepost(post.id),
                    ),
                    _ActionBtn(
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      count: post.likes,
                      active: post.isLiked,
                      activeColor: AppColors.like,
                      onTap: () => context.read<PostsProvider>().toggleLike(post.id, me.id),
                    ),
                    _ActionBtn(
                      icon: Icons.bookmark_border_rounded,
                      activeIcon: Icons.bookmark_rounded,
                      count: null,
                      active: post.isBookmarked,
                      activeColor: AppColors.primary,
                      onTap: () => context.read<PostsProvider>().toggleBookmark(post.id),
                    ),
                  ],
                ),

                // Comments section
                if (_showComments) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  ..._localComments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(user: me, size: 28, showRing: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(me.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.text)),
                              Text(c['text'] ?? '',
                                  style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  Row(
                    children: [
                      UserAvatar(user: me, size: 30, showRing: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(
                            hintText: 'Post a reply...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isEmpty) return;
                            setState(() {
                              _localComments.add({'text': val.trim()});
                              _commentCtrl.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int? count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, required this.activeIcon,
    required this.count, required this.active,
    required this.activeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 19,
              color: active ? activeColor : AppColors.text3,
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: active ? activeColor : AppColors.text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

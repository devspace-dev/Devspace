import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
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

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsP = context.watch<PostsProvider>();
    final post = postsP.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    final usersP = context.read<UsersProvider>();
    final me = context.read<AuthProvider>().currentUser;
    final user = usersP.getUserById(post.userId) ?? me;
    final lines = post.content.split('\n').where((l) => l.isNotEmpty).toList();
    final comments = postsP.commentsForPost(post.id);
    final commentsLoading = postsP.isCommentsLoading(post.id);
    final commentSubmitting = postsP.isCommentSubmitting(post.id);
    final commentError = postsP.commentError(post.id);
    final likeUpdating = postsP.isLikeUpdating(post.id);

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
                    const Text('·',
                        style: TextStyle(fontSize: 12, color: AppColors.border2)),
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
                      count: post.comments,
                      active: _showComments,
                      activeColor: AppColors.primary,
                      onTap: () {
                        final nextShowComments = !_showComments;
                        setState(() => _showComments = nextShowComments);
                        if (nextShowComments) {
                          context.read<PostsProvider>().fetchComments(post.id);
                        }
                      },
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
                      disabled: likeUpdating,
                      onTap: () => _handleLikeTap(
                        context,
                        postsP,
                        post.id,
                        me.id,
                      ),
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
                  if (commentsLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No comments yet. Start the conversation.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text3,
                        ),
                      ),
                    )
                  else
                    ...comments.map((comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommentRow(
                            comment: comment,
                            user: _commentUser(usersP, me, comment),
                          ),
                        )),
                  if (commentError != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        commentError,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
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
                          onSubmitted: (_) => _submitComment(postsP, post.id, me.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: commentSubmitting
                            ? null
                            : () => _submitComment(postsP, post.id, me.id),
                        icon: commentSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: AppColors.primary,
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

  Future<void> _submitComment(
    PostsProvider postsProvider,
    String postId,
    String userId,
  ) async {
    final success = await postsProvider.addComment(
      postId,
      userId,
      _commentCtrl.text,
    );
    if (!mounted || !success) return;
    _commentCtrl.clear();
  }

  Future<void> _handleLikeTap(
    BuildContext context,
    PostsProvider postsProvider,
    String postId,
    String userId,
  ) async {
    await postsProvider.toggleLike(postId, userId);
    if (!context.mounted) return;

    final error = postsProvider.likeError(postId);
    if (error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  UserModel _commentUser(
    UsersProvider usersProvider,
    UserModel currentUser,
    CommentModel comment,
  ) {
    final knownUser = usersProvider.getUserById(comment.userId);
    if (knownUser != null) return knownUser;
    if (comment.userId == currentUser.id) return currentUser;

    return UserModel(
      id: comment.userId,
      name: 'Student',
      handle: 'member',
      email: '',
      avatar: 'DS',
      color: AppColors.primary,
      aura: 0,
      role: '',
      year: '',
      branch: '',
      building: 'Building on DevSpace',
      stack: const [],
      followers: 0,
      following: 0,
      bio: '',
      college: '',
      githubHandle: '',
      profileCompleted: false,
    );
  }
}

class _CommentRow extends StatelessWidget {
  final CommentModel comment;
  final UserModel user;

  const _CommentRow({
    required this.comment,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(user: user, size: 28, showRing: true),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '@${user.handle}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text4,
                    ),
                  ),
                  Text(
                    timeago.format(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
  final bool disabled;

  const _ActionBtn({
    required this.icon, required this.activeIcon,
    required this.count, required this.active,
    required this.activeColor, required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 19,
              color: disabled
                  ? AppColors.text4
                  : (active ? activeColor : AppColors.text3),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: disabled
                      ? AppColors.text4
                      : (active ? activeColor : AppColors.text3),
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

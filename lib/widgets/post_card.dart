import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'user_avatar.dart';
import 'glass_container.dart';

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
    final comments = postsP.commentsForPost(post.id);
    final commentsLoading = postsP.isCommentsLoading(post.id);
    final commentSubmitting = postsP.isCommentSubmitting(post.id);
    final likeUpdating = postsP.isLikeUpdating(post.id);
    final bookmarkUpdating = postsP.isBookmarkUpdating(post.id);
    final quotePostId = post.quotePostId;
    final hasQuote = quotePostId != null && quotePostId.isNotEmpty;
    final quotedPost = hasQuote ? postsP.quotedPost(quotePostId) : null;
    final quotedPostLoading =
        hasQuote ? postsP.isQuotedPostLoading(quotePostId) : false;
    final isMe = post.userId == me.id;

    if (hasQuote && quotedPost == null && !quotedPostLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PostsProvider>().ensureQuotedPostLoaded(quotePostId);
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context, user.id),
                  child: UserAvatar(user: user, size: 38),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _openProfile(context, user.id),
                            child: Text(user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.text,
                                )),
                          ),
                          const SizedBox(width: 6),
                          Text(timeago.format(post.createdAt, locale: 'en_short'),
                              style: const TextStyle(fontSize: 13, color: AppColors.text3)),
                        ],
                      ),
                      Text('@${user.handle}',
                          style: const TextStyle(fontSize: 13, color: AppColors.text3)),
                    ],
                  ),
                ),
                if (isMe)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 20, color: AppColors.text3),
                    onPressed: () => _showPostOptions(context, post),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.text,
                height: 1.4,
              ),
            ),
          ),

          if (hasQuote) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _QuotedPostPreview(
                post: quotedPost,
                user: quotedPost == null
                    ? null
                    : _quoteUser(usersP, me, quotedPost),
                loading: quotedPostLoading,
              ),
            ),
          ],

          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PostImageThumbnail(
                imageUrl: post.imageUrl!,
                heroTag: 'post-image-${post.id}',
                maxHeight: 460,
                fit: BoxFit.contain,
                backgroundColor: Colors.black,
              ),
            ),
          ],

          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: post.tags.map((t) => Text(
                  '#$t',
                  style: const TextStyle(
                    fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
                )).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  count: post.comments,
                  active: _showComments,
                  activeColor: AppColors.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                  active: false,
                  activeColor: AppColors.repost,
                  onTap: () => _openQuoteSheet(
                    context: context,
                    originalPost: post,
                    currentUserId: me.id,
                    originalAuthor: user,
                  ),
                ),
                _ActionBtn(
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  count: post.likes,
                  active: post.isLiked,
                  activeColor: AppColors.like,
                  disabled: likeUpdating,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _handleLikeTap(
                      context,
                      postsP,
                      post.id,
                      me.id,
                    );
                  },
                ),
                _ActionBtn(
                  icon: Icons.bookmark_border_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  count: null,
                  active: post.isBookmarked,
                  activeColor: AppColors.primary,
                  disabled: bookmarkUpdating,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleBookmarkTap(
                      context,
                      postsP,
                      post.id,
                      me.id,
                    );
                  },
                ),
              ],
            ),
          ),

          // Comments section
          if (_showComments)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  if (commentsLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    )
                  else
                    ...comments.map((comment) => _CommentRow(
                          comment: comment,
                          user: _commentUser(usersP, me, comment),
                        )),
                  
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      UserAvatar(user: me, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Add a reply...',
                            hintStyle: const TextStyle(color: AppColors.text3),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            fillColor: AppColors.bg2,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _submitComment(postsP, post.id, me.id),
                        ),
                      ),
                      IconButton(
                        onPressed: commentSubmitting
                            ? null
                            : () => _submitComment(postsP, post.id, me.id),
                        icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        color: AppColors.bg2,
        opacity: 0.9,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleEditPost(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.flame),
                title: const Text('Delete Post', style: TextStyle(color: AppColors.flame)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeletePost(context, post);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEditPost(BuildContext context, PostModel post) async {
    final ctrl = TextEditingController(text: post.content);
    final nextContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Edit Post', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Update your build...',
            filled: true,
            fillColor: AppColors.bg3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (nextContent == null || nextContent.isEmpty || !context.mounted) return;
    await context.read<PostsProvider>().editPost(post.id, nextContent);
  }

  Future<void> _handleDeletePost(BuildContext context, PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.flame),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    await context.read<PostsProvider>().deletePost(post.id);
  }

  Future<void> _openQuoteSheet({
    required BuildContext context,
    required PostModel originalPost,
    required String currentUserId,
    required UserModel originalAuthor,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuotePostSheet(
        originalPost: originalPost,
        originalAuthor: originalAuthor,
        currentUserId: currentUserId,
      ),
    );
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _submitComment(
    PostsProvider postsProvider,
    String postId,
    String userId,
  ) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final success = await postsProvider.addComment(postId, userId, text);
    if (success) _commentCtrl.clear();
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
      SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleBookmarkTap(
    BuildContext context,
    PostsProvider postsProvider,
    String postId,
    String userId,
  ) async {
    await postsProvider.toggleBookmark(postId, userId);
    if (!context.mounted) return;

    final error = postsProvider.bookmarkError(postId);
    if (error == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
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

  UserModel _quoteUser(
    UsersProvider usersProvider,
    UserModel currentUser,
    PostModel quotedPost,
  ) {
    final knownUser = usersProvider.getUserById(quotedPost.userId);
    if (knownUser != null) return knownUser;
    if (quotedPost.userId == currentUser.id) return currentUser;

    return UserModel(
      id: quotedPost.userId,
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

  const _CommentRow({required this.comment, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: user, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(timeago.format(comment.createdAt, locale: 'en_short'),
                        style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotePostSheet extends StatefulWidget {
  final PostModel originalPost;
  final UserModel originalAuthor;
  final String currentUserId;

  const _QuotePostSheet({
    required this.originalPost,
    required this.originalAuthor,
    required this.currentUserId,
  });

  @override
  State<_QuotePostSheet> createState() => _QuotePostSheetState();
}

class _QuotePostSheetState extends State<_QuotePostSheet> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _posting = false;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppColors.bg,
      opacity: 0.95,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.text)),
                ),
                ElevatedButton(
                  onPressed: _posting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            _QuotedPostPreview(
              post: widget.originalPost,
              user: widget.originalAuthor,
              loading: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    final result = await context.read<PostsProvider>().addQuotePost(
          userId: widget.currentUserId,
          content: content,
          originalPostId: widget.originalPost.id,
        );
    if (mounted && result.success) Navigator.pop(context);
  }
}

class _QuotedPostPreview extends StatelessWidget {
  final PostModel? post;
  final UserModel? user;
  final bool loading;

  const _QuotedPostPreview({required this.post, required this.user, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator.adaptive());
    if (post == null || user == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: user!, size: 20),
              const SizedBox(width: 8),
              Text(user!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(post!.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _PostImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final double? maxHeight;
  final BoxFit fit;
  final Color? backgroundColor;

  const _PostImageThumbnail({
    required this.imageUrl,
    required this.heroTag,
    this.maxHeight,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: maxHeight,
      fit: fit,
      placeholder: (_, __) => Container(
        color: AppColors.bg2,
        height: maxHeight ?? 200,
      ),
    );

    if (backgroundColor != null) {
      image = Container(
        color: backgroundColor,
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Hero(
        tag: heroTag,
        child: image,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final int? count;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool disabled;

  const _ActionBtn({
    required this.icon,
    this.activeIcon,
    required this.count,
    required this.active,
    required this.onTap,
    this.activeColor,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? AppColors.primary) : AppColors.text3;
    final displayIcon = active && activeIcon != null ? activeIcon! : icon;
    
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(displayIcon, size: 18, color: color),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13, color: color, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: post.isLiked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          if (post.isLiked)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context, user.id),
                  child: UserAvatar(user: user, size: 48, showRing: true),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                GestureDetector(
                                  onTap: () => _openProfile(context, user.id),
                                  child: Text(user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppColors.text,
                                        letterSpacing: -0.4,
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () => _openProfile(context, user.id),
                                  child: Text('@${user.handle}',
                                      style: const TextStyle(
                                          fontSize: 13, color: AppColors.text3, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          Text(timeago.format(post.createdAt, locale: 'en_short'),
                              style: const TextStyle(fontSize: 12, color: AppColors.text4, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(user.building,
                          style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (isMe)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.text3),
                    color: AppColors.bg3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _handleEditPost(context, post);
                      } else if (val == 'delete') {
                        _handleDeletePost(context, post);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18, color: AppColors.text2),
                            SizedBox(width: 12),
                            Text('Edit', style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: e.key == 0 ? AppColors.text : AppColors.text2,
                      height: 1.5,
                      fontWeight: e.key == 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                )),
                if (hasQuote) ...[
                  const SizedBox(height: 14),
                  _QuotedPostPreview(
                    post: quotedPost,
                    user: quotedPost == null
                        ? null
                        : _quoteUser(usersP, me, quotedPost),
                    loading: quotedPostLoading,
                  ),
                ],
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _PostImageThumbnail(
                    imageUrl: post.imageUrl!,
                    heroTag: 'post-image-${post.id}',
                    maxHeight: 460,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.black,
                  ),
                ],
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: post.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '#$t',
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w800),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  count: post.comments,
                  active: _showComments,
                  activeColor: AppColors.mint,
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
                  activeColor: AppColors.orange,
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
                  activeColor: AppColors.primary,
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
                  activeColor: AppColors.yellow,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<PostsProvider>().toggleBookmark(post.id);
                  },
                ),
              ],
            ),
          ),

          // Comments section
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showComments 
              ? Container(
                  key: const ValueKey('comments-section'),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: AppColors.border, height: 24),
                      if (commentsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        )
                      else if (comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16, top: 8),
                          child: Text(
                            'Be the first to reply!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.text3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: comments.map((comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CommentRow(
                                  comment: comment,
                                  user: _commentUser(usersP, me, comment),
                                ),
                              )).toList(),
                        ),
                      if (commentError != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            commentError,
                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                style: const TextStyle(fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  hintText: 'Add a reply...',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onSubmitted: (_) => _submitComment(postsP, post.id, me.id),
                              ),
                            ),
                            IconButton(
                              onPressed: commentSubmitting
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _submitComment(postsP, post.id, me.id);
                                    },
                              icon: commentSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Future<void> _handleEditPost(BuildContext context, PostModel post) async {
    final ctrl = TextEditingController(text: post.content);
    final nextContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Edit Post', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Update your build...',
            filled: true,
            fillColor: AppColors.bg3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (nextContent == null || nextContent.isEmpty || !context.mounted) return;

    final success =
        await context.read<PostsProvider>().editPost(post.id, nextContent);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update post')),
      );
    }
  }

  Future<void> _handleDeletePost(BuildContext context, PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Post?',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w900)),
        content: const Text('This will permanently remove this update from the feed.',
            style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await context.read<PostsProvider>().deletePost(post.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
      );
    }
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
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) {
        return _QuotePostSheet(
          originalPost: originalPost,
          originalAuthor: originalAuthor,
          currentUserId: currentUserId,
        );
      },
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

    final success = await postsProvider.addComment(
      postId,
      userId,
      text,
    );
    if (!mounted || !success) return;
    _commentCtrl.clear();
    context.read<AuthProvider>().addAura(kAuraComment);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('+5 aura for contributing'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  const _CommentRow({
    required this.comment,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(user: user, size: 36, showRing: false),
        const SizedBox(width: 12),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '@${user.handle}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeago.format(comment.createdAt, locale: 'en_short'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.text2,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
  String? _error;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _posting = true;
      _error = null;
    });

    final result = await context.read<PostsProvider>().addQuotePost(
          userId: widget.currentUserId,
          content: content,
          originalPostId: widget.originalPost.id,
        );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _posting = false;
        _error = result.error;
      });
      return;
    }

    context.read<AuthProvider>().addAura(kAuraPost);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.warning ?? '+10 aura for sharing your take'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canPost = !_posting && _textCtrl.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quote Post',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your unique take to this update.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              minLines: 2,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'What\'s your perspective?',
                filled: true,
                fillColor: AppColors.bg3,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _QuotedPostPreview(
              post: widget.originalPost,
              user: widget.originalAuthor,
              loading: false,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _posting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: canPost ? _submit : null,
                    child: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Post Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotedPostPreview extends StatelessWidget {
  final PostModel? post;
  final UserModel? user;
  final bool loading;

  const _QuotedPostPreview({
    required this.post,
    required this.user,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Text(
              'Fetching quoted post...',
              style: TextStyle(color: AppColors.text3, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (post == null || user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: const Text(
          'Post is no longer available.',
          style: TextStyle(color: AppColors.text3, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }

    final quotedPost = post!;
    final quotedUser = user!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${quotedUser.name} @${quotedUser.handle}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (quotedPost.content.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quotedPost.content.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text2,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (quotedPost.imageUrl != null && quotedPost.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PostImageThumbnail(
              imageUrl: quotedPost.imageUrl!,
              heroTag: 'quoted-image-${quotedPost.id}',
              maxHeight: 120,
              backgroundColor: AppColors.bg,
            ),
          ],
        ],
      ),
    );
  }
}

class _PostImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final double maxHeight;
  final Color backgroundColor;
  final BoxFit fit;

  const _PostImageThumbnail({
    required this.imageUrl,
    required this.heroTag,
    required this.maxHeight,
    this.backgroundColor = AppColors.bg3,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, __, ___) => _PostImageViewerScreen(
            imageUrl: imageUrl,
            heroTag: heroTag,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: backgroundColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: fit,
                placeholder: (_, __) => Container(
                  width: double.infinity,
                  height: 200,
                  color: backgroundColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 120,
                  color: backgroundColor,
                  alignment: Alignment.center,
                  child: const Text(
                    'Unable to load image',
                    style: TextStyle(color: AppColors.text3, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _PostImageViewerScreen({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 20,
              color: disabled
                  ? AppColors.text4
                  : (active ? activeColor : AppColors.text3),
            ).animate(target: active ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.3, 1.3),
              duration: 200.ms,
              curve: Curves.elasticOut,
            ).then().scale(
              begin: const Offset(1, 1),
              end: const Offset(0.77, 0.77),
              duration: 100.ms,
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  color: disabled
                      ? AppColors.text4
                      : (active ? activeColor : AppColors.text2),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

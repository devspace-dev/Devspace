import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
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

    if (hasQuote && quotedPost == null && !quotedPostLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PostsProvider>().ensureQuotedPostLoaded(quotePostId);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + thread line
          Column(
            children: [
              GestureDetector(
                onTap: () => _openProfile(context, user.id),
                child: UserAvatar(user: user, size: 42, showRing: false),
              ),
              if (_showComments)
                Container(
                  width: 1.5, height: 60,
                  margin: const EdgeInsets.only(top: 8),
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
                                  fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                          ),
                          GestureDetector(
                            onTap: () => _openProfile(context, user.id),
                            child: Text('@${user.handle}',
                                style: const TextStyle(fontSize: 13, color: AppColors.text3)),
                          ),
                          const Text('·',
                              style: TextStyle(fontSize: 12, color: AppColors.text4)),
                          Text(timeago.format(post.createdAt, locale: 'en_short'),
                              style: const TextStyle(fontSize: 13, color: AppColors.text3)),
                        ],
                      ),
                    ),
                    AuraPill(aura: user.aura, small: true),
                  ],
                ),
                const SizedBox(height: 2),

                // Building status
                Row(
                  children: [
                    Text(user.building,
                        style: const TextStyle(fontSize: 12, color: AppColors.text4),
                        overflow: TextOverflow.ellipsis),
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
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                )),
                if (hasQuote) ...[
                  const SizedBox(height: 12),
                  _QuotedPostPreview(
                    post: quotedPost,
                    user: quotedPost == null
                        ? null
                        : _quoteUser(usersP, me, quotedPost),
                    loading: quotedPostLoading,
                  ),
                ],
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PostImageThumbnail(
                    imageUrl: post.imageUrl!,
                    heroTag: 'post-image-${post.id}',
                    maxHeight: 460,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.black,
                  ),
                ],
                const SizedBox(height: 12),

                // Tags
                if (post.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 12,
                      children: post.tags.map((t) => Text(
                        '#$t',
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                      )).toList(),
                    ),
                  ),

                // Action bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (commentsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
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
                      padding: EdgeInsets.only(bottom: 16, top: 8),
                      child: Text(
                        'No comments yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text3,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: comments.map((comment) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _CommentRow(
                                comment: comment,
                                user: _commentUser(usersP, me, comment),
                              ),
                            )).toList(),
                      ),
                    ),
                  if (commentError != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
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
                      UserAvatar(user: me, size: 28, showRing: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(fontSize: 14, color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Post a reply...',
                            filled: true,
                            fillColor: AppColors.bg2,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _submitComment(postsP, post.id, me.id),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                                size: 20,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    final success = await postsProvider.addComment(
      postId,
      userId,
      _commentCtrl.text,
    );
    if (!mounted || !success) return;
    _commentCtrl.clear();
    context.read<AuthProvider>().addAura(kAuraComment);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('+5 aura for contributing')),
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
        UserAvatar(user: user, size: 28, showRing: false),
        const SizedBox(width: 10),
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
                      color: AppColors.text3,
                    ),
                  ),
                  Text(
                    timeago.format(comment.createdAt, locale: 'en_short'),
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
                  fontSize: 14,
                  color: AppColors.text2,
                  height: 1.4,
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
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quote post',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your take and share the original post with your network.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              minLines: 3,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'What do you think about this post?',
                filled: true,
                fillColor: AppColors.bg3,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Share quote'),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading quoted post...',
              style: TextStyle(color: AppColors.text3, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (post == null || user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Quoted post unavailable',
          style: TextStyle(color: AppColors.text3, fontSize: 13),
        ),
      );
    }

    final quotedPost = post!;
    final quotedUser = user!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 16,
                color: AppColors.repost,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${quotedUser.name} @${quotedUser.handle}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (quotedPost.content.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              quotedPost.content.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text2,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
          if (quotedPost.imageUrl != null && quotedPost.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PostImageThumbnail(
              imageUrl: quotedPost.imageUrl!,
              heroTag: 'quoted-image-${quotedPost.id}',
              maxHeight: 140,
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
        borderRadius: BorderRadius.circular(12),
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
                  height: maxHeight.clamp(120.0, 220.0),
                  color: backgroundColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: double.infinity,
                  height: maxHeight.clamp(120.0, 220.0),
                  color: backgroundColor,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image unavailable',
                    style: TextStyle(
                      color: AppColors.text3,
                      fontSize: 13,
                    ),
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
      backgroundColor: Colors.black,
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
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Text(
                            'Image unavailable',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.42),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 18,
              color: disabled
                  ? AppColors.text4
                  : (active ? activeColor : AppColors.text3),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: disabled
                      ? AppColors.text4
                      : (active ? activeColor : AppColors.text3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_tag.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/people_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/profile_screen.dart';
import '../screens/post_detail_screen.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import 'glass_container.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Drives the comments toggle via ValueListenableBuilder instead of
  // setState, so opening/closing comments doesn't rebuild the whole card
  // (header, image, tags) — only the toggle icon and comments section do.
  final ValueNotifier<bool> _showCommentsNotifier = ValueNotifier<bool>(false);
  final _commentCtrl = TextEditingController();
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _showCommentsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsP = context.watch<PostsProvider>();
    final post = postsP.postById(widget.post.id) ?? widget.post;
    final usersP = context.read<UsersProvider>();
    final authP = context.read<AuthProvider>();
    final me = authP.currentUserOrNull;
    
    // Determine the author
    UserModel? user;
    if (me != null && post.userId == me.id) {
      user = me;
    } else {
      user = usersP.getUserById(post.userId);
    }
    
    // Fallback if user data not yet in provider
    final author = user ?? UserModel(
      id: post.userId,
      name: 'DevSpace Student',
      handle: 'devspace_user',
      email: '',
      avatar: 'DS',
      color: AppColors.primary,
      aura: 0,
      roles: const ['Student'],
      year: '',
      branch: '',
      building: '',
      stack: const [],
      followers: 0,
      following: 0,
      bio: '',
      college: '',
      githubHandle: '',
      profileCompleted: false,
    );

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
    final isMe = me != null && post.userId == me.id;

    if (hasQuote && quotedPost == null && !quotedPostLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PostsProvider>().ensureQuotedPostLoaded(quotePostId).then((_) {
          if (mounted) {
            final loadedQuote = context.read<PostsProvider>().quotedPost(quotePostId);
            if (loadedQuote != null) {
              context.read<UsersProvider>().fetchAndCacheUsers([loadedQuote.userId]);
            }
          }
        });
      });
    } else if (hasQuote && quotedPost != null) {
      final quoteAuthorId = quotedPost.userId;
      if (usersP.getUserById(quoteAuthorId) == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<UsersProvider>().fetchAndCacheUsers([quoteAuthorId]);
        });
      }
    }

    final surfaceColor = Ds.surface;
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Ds.border,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Author row (Top)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openProfile(context, author.id),
                    child: UserAvatar(user: author, size: 36),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openProfile(context, author.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DsText.label.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Ds.bone,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•',
                                style: DsText.caption.copyWith(
                                  color: Ds.muted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeago.format(post.createdAt, locale: 'en_short'),
                                style: DsText.caption.copyWith(
                                  fontSize: 12,
                                  color: Ds.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${author.handle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DsText.caption.copyWith(
                              fontSize: 12,
                              color: Ds.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMe)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: Ds.muted,
                      ),
                      onPressed: () => _showPostOptions(context, post),
                    ),
                ],
              ),
            ),

            // 2. Body / Media
            if (hasImage) ...[
              // Full-width edge-to-edge image
              _PostImageThumbnail(
                imageUrl: post.imageUrl!,
                heroTag: 'post-image-${post.id}',
                maxHeight: 460,
                fit: BoxFit.cover,
              ),
            ] else ...[
              // Text-only post content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                child: Text(
                  post.content,
                  style: DsText.body.copyWith(
                    fontSize: 14.5,
                    color: Ds.bone,
                    height: 1.45,
                  ),
                ),
              ),
            ],

            if (hasQuote)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: _QuotedPostPreview(
                  post: quotedPost,
                  user: quotedPost == null
                      ? null
                      : _quoteUser(usersP, me, quotedPost),
                  loading: quotedPostLoading,
                ),
              ),

            if (post.documentUrl != null && post.documentUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: _PostDocumentPreview(
                  url: post.documentUrl!,
                  name: post.documentName ?? 'Document',
                ),
              ),

            // 3. Action Row below media
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.favorite_border_rounded,
                    activeIcon: Icons.favorite_rounded,
                    count: null,
                    active: post.isLiked,
                    activeColor: AppColors.like,
                    label: 'Like',
                    disabled: likeUpdating || me == null,
                    onTap: () {
                      if (me == null) return;
                      HapticFeedback.mediumImpact();
                      _handleLikeTap(context, postsP, post.id, me.id);
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _showCommentsNotifier,
                    builder: (context, showComments, _) => _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      count: null,
                      active: showComments,
                      label: 'Comment',
                      activeColor: Ds.bone,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final next = !showComments;
                        _showCommentsNotifier.value = next;
                        if (next) {
                          context.read<PostsProvider>().fetchComments(post.id).then((_) {
                            if (mounted) {
                              final comments = context.read<PostsProvider>().commentsForPost(post.id);
                              final userIds = comments.map((c) => c.userId).toList();
                              context.read<UsersProvider>().fetchAndCacheUsers(userIds);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.repeat_rounded,
                    activeIcon: Icons.repeat_rounded,
                    count: post.reposts > 0 ? post.reposts : null,
                    active: false,
                    label: 'Repost',
                    activeColor: AppColors.repost,
                    disabled: me == null,
                    onTap: () {
                      if (me == null) return;
                      HapticFeedback.lightImpact();
                      _openQuoteSheet(
                        context: context,
                        originalPost: post,
                        currentUserId: me.id,
                        originalAuthor: author,
                      );
                    },
                  ),
                  const Spacer(),
                  _ActionBtn(
                    icon: Icons.bookmark_border_rounded,
                    activeIcon: Icons.bookmark_rounded,
                    count: null,
                    active: post.isBookmarked,
                    label: 'Save',
                    activeColor: Ds.bone,
                    disabled: bookmarkUpdating || me == null,
                    onTap: () {
                      if (me == null) return;
                      HapticFeedback.lightImpact();
                      _handleBookmarkTap(context, postsP, post.id, me.id);
                    },
                  ),
                ],
              ),
            ),

            // 4. Like count, Caption, Tags, Comment preview
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.likes} ${post.likes == 1 ? "like" : "likes"}',
                    style: DsText.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Ds.bone,
                    ),
                  ),
                  if (hasImage && post.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _PostCaption(
                      authorHandle: author.handle,
                      content: post.content,
                    ),
                  ],
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: post.tags
                          .map(
                            (t) => GestureDetector(
                              onTap: () => _openTagSearch(context, t),
                              child: DsTag(
                                '#$t',
                                bg: const Color(0xFF1E2030),
                                fg: Ds.bone,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final next = !_showCommentsNotifier.value;
                      _showCommentsNotifier.value = next;
                      if (next) {
                        context.read<PostsProvider>().fetchComments(post.id).then((_) {
                          if (mounted) {
                            final comments = context.read<PostsProvider>().commentsForPost(post.id);
                            final userIds = comments.map((c) => c.userId).toList();
                            context.read<UsersProvider>().fetchAndCacheUsers(userIds);
                          }
                        });
                      }
                    },
                    child: Text(
                      post.comments > 0
                          ? 'View all ${post.comments} ${post.comments == 1 ? "comment" : "comments"}'
                          : 'Add a comment...',
                      style: DsText.caption.copyWith(
                        fontSize: 13,
                        color: Ds.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Expandable Comments & Reply Section
            ValueListenableBuilder<bool>(
              valueListenable: _showCommentsNotifier,
              builder: (context, showComments, _) {
                if (!showComments) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Ds.border,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (commentsLoading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child:
                              Center(child: CircularProgressIndicator.adaptive()),
                        )
                      else if (comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No comments yet. Start the conversation!',
                              style: DsText.caption.copyWith(color: Ds.muted),
                            ),
                          ),
                        )
                      else
                        ...comments.map(
                          (comment) => _CommentRow(
                            comment: comment,
                            user: _commentUser(usersP, me, comment),
                            onReply: me == null ? null : () {
                              setState(() {
                                _replyingTo = comment;
                              });
                            },
                          ),
                        ),
                      if (me != null) ...[
                        const SizedBox(height: 12),
                        if (_replyingTo != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 38),
                            child: Row(
                              children: [
                                Text(
                                  'Replying to ',
                                  style: DsText.caption.copyWith(
                                    fontSize: 12,
                                    color: Ds.muted,
                                  ),
                                ),
                                Text(
                                  '@${_commentUser(usersP, me, _replyingTo!).handle}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() => _replyingTo = null),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Ds.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            UserAvatar(user: me, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                autofocus: _replyingTo != null,
                                style: DsText.body.copyWith(
                                  fontSize: 14,
                                  color: Ds.bone,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add a reply...',
                                  hintStyle: DsText.caption.copyWith(
                                    color: Ds.muted,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  fillColor: const Color(0xFF1E2030),
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: Ds.border.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: Ds.border.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) =>
                                    _submitComment(postsP, post.id, me.id),
                              ),
                            ),
                            IconButton(
                              onPressed: commentSubmitting
                                  ? null
                                  : () => _submitComment(postsP, post.id, me.id),
                              icon: const Icon(
                                Icons.arrow_upward_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        color: AppColors.bg2For(context),
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
        backgroundColor: AppColors.bg2For(context),
        title: Text('Edit Post', style: TextStyle(color: AppColors.textFor(context), fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: TextStyle(color: AppColors.textFor(context)),
          decoration: InputDecoration(
            hintText: 'Update your build...',
            filled: true,
            fillColor: AppColors.bg3For(context),
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
    final success = await context.read<PostsProvider>().editPost(
          post.id,
          nextContent,
        );
    if (!context.mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to update post.')),
    );
  }

  Future<void> _handleDeletePost(BuildContext context, PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
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
    final success = await context.read<PostsProvider>().deletePost(post.id);
    if (!context.mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete post.')),
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

  void _openTagSearch(BuildContext context, String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PeopleScreen.withQuery(initialQuery: tag),
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
      parentCommentId: _replyingTo?.id,
      replyingToUserId: _replyingTo?.userId,
    );
    
    if (!mounted) return;
    if (success) {
      _commentCtrl.clear();
      setState(() => _replyingTo = null);
      FocusScope.of(context).unfocus();
      
      final comments = postsProvider.commentsForPost(postId);
      final userIds = comments.map((c) => c.userId).toList();
      context.read<UsersProvider>().fetchAndCacheUsers(userIds);
    } else {
      final error = postsProvider.commentError(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to post comment.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.flame,
        ),
      );
    }
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
    UserModel? currentUser,
    CommentModel comment,
  ) {
    final knownUser = usersProvider.getUserById(comment.userId);
    if (knownUser != null) return knownUser;
    if (currentUser != null && comment.userId == currentUser.id) return currentUser;

    return UserModel(
      id: comment.userId,
      name: 'DevSpace Student',
      handle: 'devspace_user',
      email: '',
      avatar: 'DS',
      color: AppColors.primary,
      aura: 0,
      roles: const ['Student'],
      year: '',
      branch: '',
      building: '',
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
    UserModel? currentUser,
    PostModel quotedPost,
  ) {
    final knownUser = usersProvider.getUserById(quotedPost.userId);
    if (knownUser != null) return knownUser;
    if (currentUser != null && quotedPost.userId == currentUser.id) return currentUser;

    return UserModel(
      id: quotedPost.userId,
      name: 'DevSpace Student',
      handle: 'devspace_user',
      email: '',
      avatar: 'DS',
      color: AppColors.primary,
      aura: 0,
      roles: const ['Student'],
      year: '',
      branch: '',
      building: '',
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
  final VoidCallback? onReply;

  const _CommentRow({
    required this.comment,
    required this.user,
    this.onReply,
  });

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
                    Text(
                      user.name,
                      style: DsText.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Ds.bone,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: DsText.caption.copyWith(
                        fontSize: 12,
                        color: Ds.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: DsText.body.copyWith(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Ds.bone,
                  ),
                ),
                if (onReply != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: DsText.caption.copyWith(
                          fontSize: 12,
                          color: Ds.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
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
      color: AppColors.bgFor(context),
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
                  child: Text('Cancel', style: TextStyle(color: AppColors.textFor(context))),
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
              style: TextStyle(fontSize: 17, color: AppColors.textFor(context)),
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

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      if (result.warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.warning!)),
        );
      }
      return;
    }

    setState(() => _posting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to quote post.'),
      ),
    );
  }
}

class _QuotedPostPreview extends StatefulWidget {
  final PostModel? post;
  final UserModel? user;
  final bool loading;

  const _QuotedPostPreview({required this.post, required this.user, required this.loading});

  @override
  State<_QuotedPostPreview> createState() => _QuotedPostPreviewState();
}

class _QuotedPostPreviewState extends State<_QuotedPostPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator.adaptive()));
    if (widget.post == null || widget.user == null) return const SizedBox.shrink();

    final content = widget.post!.content;
    final isLong = content.length > 150;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: widget.post!,
              author: widget.user,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg3For(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderFor(context), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(user: widget.user!, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.user!.handle,
                  style: DsText.label.copyWith(
                    fontSize: 12,
                    color: Ds.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: _expanded ? null : 4,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: DsText.body.copyWith(
                fontSize: 13,
                height: 1.4,
                color: Ds.bone,
              ),
            ),
            if (isLong && !_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = true),
                  child: const Text(
                    'Read More',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Ds.aura,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostCaption extends StatefulWidget {
  final String authorHandle;
  final String content;

  const _PostCaption({
    required this.authorHandle,
    required this.content,
  });

  @override
  State<_PostCaption> createState() => _PostCaptionState();
}

class _PostCaptionState extends State<_PostCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.content.length > 120;
    final text = (!isLong || _expanded)
        ? widget.content
        : '${widget.content.substring(0, 120)}...';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '@${widget.authorHandle} ',
            style: DsText.label.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Ds.bone,
            ),
          ),
          TextSpan(
            text: text,
            style: DsText.body.copyWith(
              fontSize: 13.5,
              color: Ds.bone,
              height: 1.4,
            ),
          ),
          if (isLong && !_expanded)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'more',
                    style: DsText.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Ds.muted,
                    ),
                  ),
                ),
              ),
            ),
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

  const _PostImageThumbnail({
    required this.imageUrl,
    required this.heroTag,
    this.maxHeight,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final image = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: maxHeight ?? 460,
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        fit: fit,
        memCacheWidth: 1080,
        placeholder: (_, __) => Container(
          color: const Color(0xFF141622),
          height: 240,
          child: const Center(
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFF141622),
          height: 180,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: Ds.muted,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: DsText.caption.copyWith(color: Ds.muted),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _PostImageViewer(
              imageUrl: imageUrl,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: image,
      ),
    );
  }
}

class _PostImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _PostImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Hero(
                tag: heroTag,
                child: image,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
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
  final String label;

  const _ActionBtn({
    required this.icon,
    this.activeIcon,
    this.count,
    required this.active,
    required this.onTap,
    required this.label,
    this.activeColor,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? (activeColor ?? AppColors.primary) : Ds.muted;
    final displayIcon = active && activeIcon != null ? activeIcon! : icon;

    return Semantics(
      label: label,
      button: true,
      enabled: !disabled,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(displayIcon, size: 22, color: color),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDocumentPreview extends StatelessWidget {
  final String url;
  final String name;

  const _PostDocumentPreview({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderFor(context).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DsText.label.copyWith(
                  fontSize: 14,
                  color: Ds.bone,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.text3For(context),
            ),
          ],
        ),
      ),
    );
  }
}


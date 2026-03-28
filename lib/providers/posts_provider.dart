import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class PostCreateResult {
  final bool success;
  final String? error;
  final String? warning;

  const PostCreateResult({
    required this.success,
    this.error,
    this.warning,
  });
}

class PostsProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  List<PostModel> _savedPosts = [];
  final Map<String, PostModel> _quotedPosts = {};
  final Map<String, List<CommentModel>> _commentsByPost = {};
  final Map<String, bool> _commentsLoading = {};
  final Map<String, bool> _commentSubmitting = {};
  final Map<String, String?> _commentErrors = {};
  final Map<String, bool> _likeUpdating = {};
  final Map<String, String?> _likeErrors = {};
  final Map<String, bool> _bookmarkUpdating = {};
  final Map<String, String?> _bookmarkErrors = {};
  final Map<String, bool> _quoteLoading = {};
  bool _isLoading = false;
  bool _savedPostsLoading = false;
  bool _savedPostsLoaded = false;
  String? _feedError;
  String? _savedPostsError;
  StreamSubscription<List<PostModel>>? _feedSub;

  List<PostModel> get posts => List.unmodifiable(_posts);
  List<PostModel> get savedPosts => List.unmodifiable(_savedPosts);
  bool get isLoading => _isLoading;
  bool get isSavedPostsLoading => _savedPostsLoading;
  String? get feedError => _feedError;
  String? get savedPostsError => _savedPostsError;
  List<PostModel> postsForUser(String userId) =>
      _posts.where((post) => post.userId == userId).toList();
  List<CommentModel> commentsForPost(String postId) =>
      List.unmodifiable(_commentsByPost[postId] ?? const []);
  bool isCommentsLoading(String postId) => _commentsLoading[postId] ?? false;
  bool isCommentSubmitting(String postId) =>
      _commentSubmitting[postId] ?? false;
  String? commentError(String postId) => _commentErrors[postId];
  bool isLikeUpdating(String postId) => _likeUpdating[postId] ?? false;
  String? likeError(String postId) => _likeErrors[postId];
  bool isBookmarkUpdating(String postId) => _bookmarkUpdating[postId] ?? false;
  String? bookmarkError(String postId) => _bookmarkErrors[postId];
  PostModel? quotedPost(String postId) =>
      _quotedPosts[postId] ?? _findPost(postId);
  bool isQuotedPostLoading(String postId) => _quoteLoading[postId] ?? false;

  static bool canCreatePost(String content, {File? imageFile}) {
    return content.trim().isNotEmpty || imageFile != null;
  }

  Future<void> fetchFeed() async {
    if (_feedSub != null) {
      await _feedSub!.cancel();
    }
    _isLoading = true;
    _feedError = null;
    notifyListeners();

    final completer = Completer<void>();
    late final StreamSubscription<List<PostModel>> subscription;

    void completeOnce() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    subscription = SupabaseService.instance.streamFeed().listen(
      (newList) async {
        try {
          final currentUser = AuthService.instance.currentUser;
          if (currentUser == null) {
            _posts = newList;
          } else {
            final results = await Future.wait<dynamic>([
              SupabaseService.instance.getLikedPostIds(currentUser.id),
              SupabaseService.instance.getBookmarkedPostIds(currentUser.id),
            ]);
            final likedPostIds = results[0] as Set<String>;
            final bookmarkedPostIds = results[1] as Set<String>;
            _posts = newList
                .map(
                  (post) =>
                      _mergeHydratedPost(post, likedPostIds, bookmarkedPostIds),
                )
                .toList();
            _rehydrateSavedPosts(likedPostIds, bookmarkedPostIds);
          }
          _feedError = null;
        } catch (e) {
          _feedError = 'Failed to load feed: $e';
        } finally {
          _isLoading = false;
          notifyListeners();
          completeOnce();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _feedError = 'Failed to load feed: $error';
        _isLoading = false;
        notifyListeners();
        completeOnce();
      },
    );

    _feedSub = subscription;
    await completer.future;
  }

  Future<void> refreshFeed() => fetchFeed();

  Future<PostCreateResult> addPost(
    String userId,
    String content,
    List<String> tags, {
    File? imageFile,
    String? quotePostId,
  }) async {
    final trimmedContent = content.trim();
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    if (!canCreatePost(trimmedContent, imageFile: imageFile)) {
      return const PostCreateResult(
        success: false,
        error: 'Add some text or attach an image to post.',
      );
    }

    try {
      var uploadedImageUrl = '';
      if (imageFile != null) {
        try {
          uploadedImageUrl =
              await StorageService.instance.uploadPostImageForDraft(imageFile);
        } catch (e) {
          return PostCreateResult(
            success: false,
            error: 'Failed to upload post image: $e',
          );
        }
      }

      await SupabaseService.instance.createPost(
        userId: userId,
        content: trimmedContent,
        tags: normalizedTags,
        imageUrl: uploadedImageUrl,
        quotePostId: quotePostId,
      );
      return PostCreateResult(
        success: true,
        warning: imageFile != null && uploadedImageUrl.isEmpty
            ? 'Post published without image.'
            : null,
      );
    } catch (e) {
      return PostCreateResult(
        success: false,
        error: 'Failed to publish post: $e',
      );
    }
  }

  Future<PostCreateResult> addQuotePost({
    required String userId,
    required String content,
    required String originalPostId,
  }) {
    return addPost(
      userId,
      content,
      const [],
      quotePostId: originalPostId,
    );
  }

  Future<bool> editPost(String postId, String content) async {
    try {
      await SupabaseService.instance.updatePost(postId, content);
      _posts = _posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(content: content);
        }
        return post;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await SupabaseService.instance.deletePost(postId);
      _posts = _posts.where((post) => post.id != postId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    if (_likeUpdating[postId] == true) return;

    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final nextIsLiked = !post.isLiked;
    final nextLikes =
        nextIsLiked ? post.likes + 1 : (post.likes > 0 ? post.likes - 1 : 0);

    _posts[postIndex] = post.copyWith(
      isLiked: nextIsLiked,
      likes: nextLikes,
    );
    _likeUpdating[postId] = true;
    _likeErrors[postId] = null;
    notifyListeners();

    try {
      if (nextIsLiked) {
        await SupabaseService.instance.likePost(postId, userId);
      } else {
        await SupabaseService.instance.unlikePost(postId, userId);
      }
      await _refreshPostLikeState(postId, userId);
    } catch (e) {
      _posts[postIndex] = post;
      _likeErrors[postId] = 'Failed to update like: $e';
    } finally {
      _likeUpdating[postId] = false;
      notifyListeners();
    }
  }

  Future<void> fetchComments(String postId, {bool force = false}) async {
    if (_commentsLoading[postId] == true) return;
    if (!force && _commentsByPost.containsKey(postId)) return;

    _commentsLoading[postId] = true;
    _commentErrors[postId] = null;
    notifyListeners();

    try {
      final comments =
          await SupabaseService.instance.getCommentsForPost(postId);
      _commentsByPost[postId] = comments;
    } catch (e) {
      _commentErrors[postId] = 'Failed to load comments: $e';
    } finally {
      _commentsLoading[postId] = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(String postId, String userId, String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      _commentErrors[postId] = 'Comment cannot be empty.';
      notifyListeners();
      return false;
    }

    _commentSubmitting[postId] = true;
    _commentErrors[postId] = null;
    notifyListeners();

    try {
      await SupabaseService.instance.addComment(postId, userId, trimmedText);
      final comments =
          await SupabaseService.instance.getCommentsForPost(postId);
      _commentsByPost[postId] = comments;
      _commentErrors[postId] = null;
      _posts = _posts.map((post) {
        if (post.id != postId) return post;
        return post.copyWith(comments: comments.length);
      }).toList();
      return true;
    } catch (e) {
      _commentErrors[postId] = 'Failed to post comment: $e';
      return false;
    } finally {
      _commentSubmitting[postId] = false;
      notifyListeners();
    }
  }

  Future<void> toggleRepost(String postId) async {
    _posts = _posts.map((post) {
      if (post.id != postId) return post;
      final isReposted = !post.isReposted;
      final nextReposts = isReposted
          ? post.reposts + 1
          : (post.reposts > 0 ? post.reposts - 1 : 0);
      return post.copyWith(
        isReposted: isReposted,
        reposts: nextReposts,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> ensureQuotedPostLoaded(String postId) async {
    if (postId.isEmpty) return;
    if (_findPost(postId) != null || _quotedPosts.containsKey(postId)) return;
    if (_quoteLoading[postId] == true) return;

    _quoteLoading[postId] = true;
    notifyListeners();

    try {
      final post = await SupabaseService.instance.getPostById(postId);
      if (post != null) {
        _quotedPosts[postId] = post;
      }
    } finally {
      _quoteLoading[postId] = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String postId, [String? userId]) async {
    final resolvedUserId = userId ?? AuthService.instance.currentUser?.id;
    if (resolvedUserId == null) {
      _bookmarkErrors[postId] = 'You need to be signed in to save posts.';
      notifyListeners();
      return;
    }
    if (_bookmarkUpdating[postId] == true) return;

    final currentPost = _findPost(postId) ?? _findSavedPost(postId);
    if (currentPost == null) return;

    final nextIsBookmarked = !currentPost.isBookmarked;
    _applyBookmarkState(
      postId,
      nextIsBookmarked,
      sourcePost: currentPost,
    );
    _bookmarkUpdating[postId] = true;
    _bookmarkErrors[postId] = null;
    notifyListeners();

    try {
      if (nextIsBookmarked) {
        await SupabaseService.instance.bookmarkPost(postId, resolvedUserId);
      } else {
        await SupabaseService.instance.removeBookmark(postId, resolvedUserId);
      }
      _bookmarkErrors[postId] = null;
      if (_savedPostsLoaded) {
        await fetchBookmarkedPosts(resolvedUserId, force: true);
      }
    } catch (e) {
      _applyBookmarkState(
        postId,
        currentPost.isBookmarked,
        sourcePost: currentPost,
      );
      _bookmarkErrors[postId] = 'Failed to update saved post: $e';
    } finally {
      _bookmarkUpdating[postId] = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookmarkedPosts(String userId, {bool force = false}) async {
    if (_savedPostsLoading) return;
    if (_savedPostsLoaded && !force) return;

    _savedPostsLoading = true;
    _savedPostsError = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getBookmarkedPosts(userId),
        SupabaseService.instance.getLikedPostIds(userId),
      ]);
      final bookmarkedPosts = results[0] as List<PostModel>;
      final likedPostIds = results[1] as Set<String>;
      _savedPosts = bookmarkedPosts.map((post) {
        final feedPost = _findPost(post.id);
        final mergedPost = feedPost ?? post;
        return mergedPost.copyWith(
          isLiked: likedPostIds.contains(post.id),
          isBookmarked: true,
        );
      }).toList();
      _savedPostsLoaded = true;
      _savedPostsError = null;
    } catch (e) {
      _savedPostsError = 'Failed to load saved posts: $e';
    } finally {
      _savedPostsLoading = false;
      notifyListeners();
    }
  }

  PostModel _mergeHydratedPost(
    PostModel hydratedPost,
    Set<String> likedPostIds,
    Set<String> bookmarkedPostIds,
  ) {
    final existingPost = _findPost(hydratedPost.id);
    if (existingPost == null) {
      return hydratedPost.copyWith(
        isLiked: likedPostIds.contains(hydratedPost.id),
        isBookmarked: bookmarkedPostIds.contains(hydratedPost.id),
      );
    }

    final likeUpdating = _likeUpdating[hydratedPost.id] == true;
    final bookmarkUpdating = _bookmarkUpdating[hydratedPost.id] == true;

    return hydratedPost.copyWith(
      isLiked: likeUpdating
          ? existingPost.isLiked
          : likedPostIds.contains(hydratedPost.id),
      likes: likeUpdating ? existingPost.likes : hydratedPost.likes,
      isBookmarked: bookmarkUpdating
          ? existingPost.isBookmarked
          : bookmarkedPostIds.contains(hydratedPost.id),
      isReposted: existingPost.isReposted,
    );
  }

  Future<void> _refreshPostLikeState(String postId, String userId) async {
    final refreshedPost = await SupabaseService.instance.getPostById(postId);
    if (refreshedPost == null) return;

    final isLiked = await SupabaseService.instance.hasLiked(postId, userId);
    _posts = _posts.map((post) {
      if (post.id != postId) return post;
      return refreshedPost.copyWith(
        isLiked: isLiked,
        isBookmarked: post.isBookmarked,
        isReposted: post.isReposted,
      );
    }).toList();
    _savedPosts = _savedPosts.map((post) {
      if (post.id != postId) return post;
      return refreshedPost.copyWith(
        isLiked: isLiked,
        isBookmarked: post.isBookmarked,
        isReposted: post.isReposted,
      );
    }).toList();
    _likeErrors[postId] = null;
  }

  void _applyBookmarkState(
    String postId,
    bool isBookmarked, {
    required PostModel sourcePost,
  }) {
    _posts = _posts.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(isBookmarked: isBookmarked);
    }).toList();

    final savedPostIndex = _savedPosts.indexWhere((post) => post.id == postId);
    if (isBookmarked) {
      if (savedPostIndex >= 0) {
        _savedPosts[savedPostIndex] = _savedPosts[savedPostIndex].copyWith(
          isBookmarked: true,
        );
      } else if (_savedPostsLoaded) {
        _savedPosts = [
          sourcePost.copyWith(isBookmarked: true),
          ..._savedPosts,
        ];
      }
      return;
    }

    _savedPosts = _savedPosts.where((post) => post.id != postId).toList();
  }

  void _rehydrateSavedPosts(
    Set<String> likedPostIds,
    Set<String> bookmarkedPostIds,
  ) {
    if (!_savedPostsLoaded && _savedPosts.isEmpty) return;

    _savedPosts = _savedPosts
        .map((post) {
          final feedPost = _findPost(post.id);
          final basePost = feedPost ?? post;
          return basePost.copyWith(
            isLiked: likedPostIds.contains(post.id),
            isBookmarked: bookmarkedPostIds.contains(post.id),
          );
        })
        .where((post) => post.isBookmarked)
        .toList();
  }

  PostModel? _findPost(String postId) {
    try {
      return _posts.firstWhere((post) => post.id == postId);
    } catch (_) {
      return null;
    }
  }

  PostModel? _findSavedPost(String postId) {
    try {
      return _savedPosts.firstWhere((post) => post.id == postId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }
}

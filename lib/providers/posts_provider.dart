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
  final Map<String, List<CommentModel>> _commentsByPost = {};
  final Map<String, bool> _commentsLoading = {};
  final Map<String, bool> _commentSubmitting = {};
  final Map<String, String?> _commentErrors = {};
  final Map<String, bool> _likeUpdating = {};
  final Map<String, String?> _likeErrors = {};
  bool _isLoading = false;
  String? _feedError;
  StreamSubscription<List<PostModel>>? _feedSub;

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get feedError => _feedError;
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
            final likedPostIds =
                await SupabaseService.instance.getLikedPostIds(currentUser.id);
            _posts = newList
                .map((post) => _mergeHydratedPost(post, likedPostIds))
                .toList();
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
  }) async {
    try {
      final postId = await SupabaseService.instance.createPost(
        userId: userId,
        content: content,
        tags: tags,
      );

      if (imageFile == null) {
        return const PostCreateResult(success: true);
      }

      try {
        final imageUrl =
            await StorageService.instance.uploadPostImage(postId, imageFile);
        await SupabaseService.instance.updatePostImage(postId, imageUrl);
        return const PostCreateResult(success: true);
      } catch (e) {
        return PostCreateResult(
          success: true,
          warning:
              'Your post was published, but the image failed to upload: $e',
        );
      }
    } catch (e) {
      return PostCreateResult(
        success: false,
        error: 'Failed to publish post: $e',
      );
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    if (_likeUpdating[postId] == true) return;

    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final nextIsLiked = !post.isLiked;
    final nextLikes = nextIsLiked
        ? post.likes + 1
        : (post.likes > 0 ? post.likes - 1 : 0);

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
      final comments = await SupabaseService.instance.getCommentsForPost(postId);
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
      final comments = await SupabaseService.instance.getCommentsForPost(postId);
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

  Future<void> toggleBookmark(String postId, [String? userId]) async {
    _posts = _posts.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(isBookmarked: !post.isBookmarked);
    }).toList();
    notifyListeners();
  }

  PostModel _mergeHydratedPost(
    PostModel hydratedPost,
    Set<String> likedPostIds,
  ) {
    final existingPost = _findPost(hydratedPost.id);
    if (existingPost == null) {
      return hydratedPost.copyWith(
        isLiked: likedPostIds.contains(hydratedPost.id),
      );
    }

    if (_likeUpdating[hydratedPost.id] == true) {
      return hydratedPost.copyWith(
        isLiked: existingPost.isLiked,
        likes: existingPost.likes,
        isBookmarked: existingPost.isBookmarked,
        isReposted: existingPost.isReposted,
      );
    }

    return hydratedPost.copyWith(
      isLiked: likedPostIds.contains(hydratedPost.id),
      isBookmarked: existingPost.isBookmarked,
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
    _likeErrors[postId] = null;
  }

  PostModel? _findPost(String postId) {
    try {
      return _posts.firstWhere((post) => post.id == postId);
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

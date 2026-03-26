import 'dart:async';

import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class PostsProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _commentsByPost = {};
  final Map<String, bool> _commentsLoading = {};
  final Map<String, bool> _commentSubmitting = {};
  final Map<String, String?> _commentErrors = {};
  bool _isLoading = false;
  StreamSubscription<List<PostModel>>? _feedSub;

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  List<PostModel> postsForUser(String userId) =>
      _posts.where((post) => post.userId == userId).toList();
  List<CommentModel> commentsForPost(String postId) =>
      List.unmodifiable(_commentsByPost[postId] ?? const []);
  bool isCommentsLoading(String postId) => _commentsLoading[postId] ?? false;
  bool isCommentSubmitting(String postId) =>
      _commentSubmitting[postId] ?? false;
  String? commentError(String postId) => _commentErrors[postId];

  Future<void> fetchFeed() async {
    if (_feedSub != null) {
      await _feedSub!.cancel();
    }
    _isLoading = true;
    notifyListeners();

    _feedSub = SupabaseService.instance.streamFeed().listen((newList) async {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        _posts = newList;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final likedPostIds =
          await SupabaseService.instance.getLikedPostIds(currentUser.id);
      _posts = newList
          .map(
            (post) => post.copyWith(
              isLiked: likedPostIds.contains(post.id),
            ),
          )
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addPost(String userId, String content, List<String> tags) async {
    await SupabaseService.instance.createPost(
      userId: userId,
      content: content,
      tags: tags,
    );
    // Stream will handle the update
  }

  Future<void> toggleLike(String postId, String userId) async {
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
    notifyListeners();

    try {
      if (nextIsLiked) {
        await SupabaseService.instance.likePost(postId, userId);
      } else {
        await SupabaseService.instance.unlikePost(postId, userId);
      }
    } catch (e) {
      _posts[postIndex] = post;
      _commentErrors[postId] = 'Failed to update like: $e';
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

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }
}

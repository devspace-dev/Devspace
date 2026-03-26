import 'dart:async';

import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/mongo_service.dart';

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

    final initialPosts = await MongoService.instance.streamFeed().first;
    _posts = initialPosts;
    _isLoading = false;
    notifyListeners();

    _feedSub = MongoService.instance.feedStream.listen((newList) {
      _posts = newList;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addPost(String userId, String content, List<String> tags) async {
    await MongoService.instance.createPost(
      userId: userId,
      content: content,
      tags: tags,
    );
    // Stream will handle the update
  }

  Future<void> toggleLike(String postId, String userId) async {
    final hasLiked = await MongoService.instance.hasLiked(postId, userId);
    if (hasLiked) {
      await MongoService.instance.unlikePost(postId, userId);
    } else {
      await MongoService.instance.likePost(postId, userId);
    }
    // Refresh feed or handle local update
  }

  Future<void> fetchComments(String postId, {bool force = false}) async {
    if (_commentsLoading[postId] == true) return;
    if (!force && _commentsByPost.containsKey(postId)) return;

    _commentsLoading[postId] = true;
    _commentErrors[postId] = null;
    notifyListeners();

    try {
      final comments = await MongoService.instance.getCommentsForPost(postId);
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
      await MongoService.instance.addComment(postId, userId, trimmedText);
      final comments = await MongoService.instance.getCommentsForPost(postId);
      _commentsByPost[postId] = comments;
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

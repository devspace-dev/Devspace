import 'dart:async';

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/mongo_service.dart';

class PostsProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  StreamSubscription<List<PostModel>>? _feedSub;

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  List<PostModel> postsForUser(String userId) =>
      _posts.where((post) => post.userId == userId).toList();

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

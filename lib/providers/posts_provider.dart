import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/mongo_service.dart';

class PostsProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;

  Future<void> fetchFeed() async {
    _isLoading = true;
    notifyListeners();
    
    // In a real app we'd use streams, but for this provider we'll fetch once or listen
    MongoService.instance.streamFeed().listen((newList) {
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

  Future<void> toggleBookmark(String postId, String userId) async {
    // Implement bookmarking if needed in MongoService
  }
}

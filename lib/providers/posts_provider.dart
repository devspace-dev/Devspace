import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../data/mock_posts.dart';

class PostsProvider extends ChangeNotifier {
  final List<PostModel> _posts = List.from(kMockPosts);
  final _uuid = const Uuid();

  List<PostModel> get posts => List.unmodifiable(_posts);

  void addPost(int userId, String content, List<String> tags) {
    final post = PostModel(
      id: _uuid.v4(), userId: userId,
      content: content, tags: tags,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    notifyListeners();
  }

  void toggleLike(String postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final p = _posts[i];
    _posts[i] = p.copyWith(
      isLiked: !p.isLiked,
      likes: p.isLiked ? p.likes - 1 : p.likes + 1,
    );
    notifyListeners();
  }

  void toggleBookmark(String postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    _posts[i] = _posts[i].copyWith(isBookmarked: !_posts[i].isBookmarked);
    notifyListeners();
  }

  void toggleRepost(String postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i < 0) return;
    final p = _posts[i];
    _posts[i] = p.copyWith(
      isReposted: !p.isReposted,
      reposts: p.isReposted ? p.reposts - 1 : p.reposts + 1,
    );
    notifyListeners();
  }

  List<PostModel> postsForUser(int userId) =>
      _posts.where((p) => p.userId == userId).toList();
}

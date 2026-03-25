class PostModel {
  final String id;
  final int userId;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  int likes;
  int comments;
  int reposts;
  bool isLiked;
  bool isBookmarked;
  bool isReposted;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isReposted = false,
  });

  PostModel copyWith({
    int? likes, int? comments, int? reposts,
    bool? isLiked, bool? isBookmarked, bool? isReposted,
  }) {
    return PostModel(
      id: id, userId: userId, content: content,
      tags: tags, createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isReposted: isReposted ?? this.isReposted,
    );
  }
}

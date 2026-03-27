class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> tags;
  final String? imageUrl;
  final String? quotePostId;
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
    this.imageUrl,
    this.quotePostId,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isReposted = false,
  });

  PostModel copyWith({
    String? content,
    String? imageUrl,
    String? quotePostId,
    int? likes,
    int? comments,
    int? reposts,
    bool? isLiked,
    bool? isBookmarked,
    bool? isReposted,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      content: content ?? this.content,
      tags: tags,
      imageUrl: imageUrl ?? this.imageUrl,
      quotePostId: quotePostId ?? this.quotePostId,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isReposted: isReposted ?? this.isReposted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'content': content,
        'tags': tags,
        'imageUrl': imageUrl,
        'quotePostId': quotePostId,
        'likes': likes,
        'comments': comments,
        'reposts': reposts,
        'createdAt': createdAt,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return PostModel(
      id: (json['id'] ?? '0').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '0').toString(),
      content: json['content'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      quotePostId: (json['quote_post_id'] ?? json['quotePostId'])?.toString(),
      createdAt: _parseDateTime(createdAtValue),
      likes: (json['likes_count'] ?? json['likes'] ?? 0) as int,
      comments: (json['comments_count'] ?? json['comments'] ?? 0) as int,
      reposts: (json['reposts_count'] ?? json['reposts'] ?? 0) as int,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}

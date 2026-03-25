import 'package:mongo_dart/mongo_dart.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> tags;
  final String? imageUrl;
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
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.reposts = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isReposted = false,
  });

  PostModel copyWith({
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
      content: content,
      tags: tags,
      imageUrl: imageUrl,
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
        '_id': ObjectId.fromHexString(id),
        'userId': ObjectId.fromHexString(userId),
        'content': content,
        'tags': tags,
        'imageUrl': imageUrl,
        'likes': likes,
        'comments': comments,
        'reposts': reposts,
        'createdAt': createdAt,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['_id'] as ObjectId).oid,
      userId: (json['userId'] as ObjectId).oid,
      content: json['content'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as DateTime).toLocal(),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      reposts: json['reposts'] as int? ?? 0,
    );
  }
}

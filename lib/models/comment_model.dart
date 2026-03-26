import 'package:mongo_dart/mongo_dart.dart';

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: (json['_id'] as ObjectId).oid,
      postId: (json['postId'] as ObjectId).oid,
      userId: (json['uid'] as ObjectId).oid,
      text: json['text'] as String? ?? '',
      createdAt: (json['createdAt'] as DateTime).toLocal(),
    );
  }
}

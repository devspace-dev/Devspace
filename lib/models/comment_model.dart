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
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return CommentModel(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? json['postId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['uid'] ?? '').toString(),
      text: (json['content'] ?? json['text'] ?? '').toString(),
      createdAt: _parseDateTime(createdAtValue),
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

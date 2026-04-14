class NotificationModel {
  final String id;
  final String toUid;
  final String fromUid;
  final String type;
  final String? postId;
  final String? questionId;
  final String message;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.toUid,
    required this.fromUid,
    required this.type,
    this.postId,
    this.questionId,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      toUid: json['to_uid']?.toString() ?? '',
      fromUid: json['from_uid']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      postId: json['post_id']?.toString(),
      questionId: json['question_id']?.toString(),
      message: json['message']?.toString() ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'to_uid': toUid,
      'from_uid': fromUid,
      'type': type,
      'post_id': postId,
      'question_id': questionId,
      'message': message,
      'read': read,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

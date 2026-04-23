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
  final Map<String, dynamic>? payload;

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
    this.payload,
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
      payload: json['payload'] as Map<String, dynamic>?,
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
      'payload': payload,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? toUid,
    String? fromUid,
    String? type,
    String? postId,
    String? questionId,
    String? message,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      toUid: toUid ?? this.toUid,
      fromUid: fromUid ?? this.fromUid,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      questionId: questionId ?? this.questionId,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }
}

class NotificationModel {
  final String id;
  final String toUid;
  final String fromUid;
  final String type;
  final String? postId;
  final String message;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.toUid,
    required this.fromUid,
    required this.type,
    this.postId,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      toUid: json['to_uid'],
      fromUid: json['from_uid'],
      type: json['type'] ?? '',
      postId: json['post_id'],
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'to_uid': toUid,
      'from_uid': fromUid,
      'type': type,
      'post_id': postId,
      'message': message,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

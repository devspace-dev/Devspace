class ConversationModel {
  final String id;
  final List<String> participants;
  final String participantKey;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    this.participantKey = '',
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    required this.createdAt,
    this.updatedAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      participants: List<String>.from(json['participants'] as List? ?? []),
      participantKey: json['participant_key']?.toString() ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      unreadCount: (json['unread_count'] as num? ?? 0).toInt(),
    );
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? participantKey,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantKey: participantKey ?? this.participantKey,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participants': participants,
        'participant_key': participantKey,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'last_message_sender_id': lastMessageSenderId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'unread_count': unreadCount,
      };
}

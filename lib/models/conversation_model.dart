class ConversationModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      participants: List<String>.from(json['participants'] as List? ?? []),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participants': participants,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class QuestionReplyModel {
  final String id;
  final String questionId;
  final String userId;
  final String content;
  final DateTime createdAt;

  const QuestionReplyModel({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory QuestionReplyModel.fromJson(Map<String, dynamic> json) {
    return QuestionReplyModel(
      id: (json['id'] ?? '').toString(),
      questionId: (json['question_id'] ?? json['questionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      content: (json['content'] ?? '') as String,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      ).toLocal(),
    );
  }
}

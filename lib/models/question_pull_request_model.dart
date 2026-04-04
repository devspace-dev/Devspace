class QuestionPullRequestModel {
  final String id;
  final String questionId;
  final String userId;
  final String status; // 'pending', 'accepted', 'rejected'
  final String message;
  final DateTime createdAt;

  const QuestionPullRequestModel({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory QuestionPullRequestModel.fromJson(Map<String, dynamic> json) {
    return QuestionPullRequestModel(
      id: (json['id'] ?? '').toString(),
      questionId: (json['question_id'] ?? json['questionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      status: (json['status'] ?? 'pending') as String,
      message: (json['message'] ?? '') as String,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      ).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'user_id': userId,
      'status': status,
      'message': message,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}

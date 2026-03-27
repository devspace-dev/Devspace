class QuestionReplyModel {
  final String id;
  final String questionId;
  final String userId;
  final String content;
  final String? parentReplyId;
  final String? replyingToUserId;
  final DateTime createdAt;

  const QuestionReplyModel({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.content,
    this.parentReplyId,
    this.replyingToUserId,
    required this.createdAt,
  });

  bool get isTopLevel =>
      parentReplyId == null || parentReplyId!.trim().isEmpty;

  factory QuestionReplyModel.fromJson(Map<String, dynamic> json) {
    final rawParentReplyId =
        (json['parent_reply_id'] ?? json['parentReplyId'])?.toString().trim();
    final rawReplyingToUserId =
        (json['replying_to_user_id'] ?? json['replyingToUserId'])
            ?.toString()
            .trim();

    return QuestionReplyModel(
      id: (json['id'] ?? '').toString(),
      questionId: (json['question_id'] ?? json['questionId'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      content: (json['content'] ?? '') as String,
      parentReplyId:
          rawParentReplyId == null || rawParentReplyId.isEmpty
              ? null
              : rawParentReplyId,
      replyingToUserId:
          rawReplyingToUserId == null || rawReplyingToUserId.isEmpty
              ? null
              : rawReplyingToUserId,
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      ).toLocal(),
    );
  }
}

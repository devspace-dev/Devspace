class QuestionModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final int upvotesCount;
  final int repliesCount;
  final String? solvedReplyId;
  final bool isUpvoted;

  const QuestionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.upvotesCount,
    required this.repliesCount,
    this.solvedReplyId,
    this.isUpvoted = false,
  });

  bool get isSolved =>
      solvedReplyId != null && solvedReplyId!.trim().isNotEmpty;

  QuestionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    List<String>? tags,
    DateTime? createdAt,
    int? upvotesCount,
    int? repliesCount,
    String? solvedReplyId,
    bool clearSolvedReplyId = false,
    bool? isUpvoted,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      solvedReplyId: clearSolvedReplyId
          ? null
          : (solvedReplyId ?? this.solvedReplyId),
      isUpvoted: isUpvoted ?? this.isUpvoted,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      createdAt: DateTime.parse(
        (json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      ).toLocal(),
      upvotesCount: (json['upvotes_count'] as num?)?.toInt() ?? 0,
      repliesCount: (json['replies_count'] as num?)?.toInt() ?? 0,
      solvedReplyId: (json['solved_reply_id'] ?? json['solvedReplyId'])
              ?.toString()
              .trim()
              .isEmpty ??
          true
          ? null
          : (json['solved_reply_id'] ?? json['solvedReplyId']).toString(),
      isUpvoted: (json['is_upvoted'] ?? json['isUpvoted']) as bool? ?? false,
    );
  }
}

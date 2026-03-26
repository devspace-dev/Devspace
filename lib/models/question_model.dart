class QuestionModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  int votes;
  int answerCount;
  bool isSolved;
  int? userVote; // 1 = up, -1 = down, null = none

  QuestionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    this.votes = 0,
    this.answerCount = 0,
    this.isSolved = false,
    this.userVote,
  });

  QuestionModel copyWith({
    int? votes, int? answerCount, bool? isSolved, int? userVote,
  }) {
    return QuestionModel(
      id: id, userId: userId, title: title, body: body,
      tags: tags, createdAt: createdAt,
      votes: votes ?? this.votes,
      answerCount: answerCount ?? this.answerCount,
      isSolved: isSolved ?? this.isSolved,
      userVote: userVote,
    );
  }
}

class ChallengeQuestion {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final List<String> tags;
  final String topic;
  final String? hint;
  final String? solution;
  final String? careerGoal;
  final int week;
  final bool isPremium;

  ChallengeQuestion({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.tags,
    required this.topic,
    this.hint,
    this.solution,
    this.careerGoal,
    required this.week,
    required this.isPremium,
  });

  factory ChallengeQuestion.fromMap(Map<String, dynamic> map) {
    return ChallengeQuestion(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? 'Medium',
      tags: List<String>.from(map['tags'] ?? []),
      topic: map['topic'] ?? '',
      hint: map['hint'],
      solution: map['solution'],
      careerGoal: map['career_goal'],
      week: map['week'] ?? 0,
      isPremium: map['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'tags': tags,
      'topic': topic,
      'hint': hint,
      'solution': solution,
      'career_goal': careerGoal,
      'week': week,
      'is_premium': isPremium,
    };
  }
}

class DailyChallengeModel {
  final String assignmentId;
  final String challengeId;
  final DateTime? assignedDate;
  final String selectedTechStack;
  final bool completed;
  final DateTime? completedAt;
  final String title;
  final String description;
  final String difficulty;
  final String techStack;
  final int pointsReward;

  const DailyChallengeModel({
    required this.assignmentId,
    required this.challengeId,
    required this.assignedDate,
    required this.selectedTechStack,
    required this.completed,
    required this.completedAt,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.techStack,
    required this.pointsReward,
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    final challenge = Map<String, dynamic>.from(
      (json['challenge'] as Map?) ?? const {},
    );

    return DailyChallengeModel(
      assignmentId: (json['id'] ?? '').toString(),
      challengeId: (json['challenge_id'] ?? challenge['id'] ?? '').toString(),
      assignedDate: json['assigned_date'] == null
          ? null
          : DateTime.tryParse(json['assigned_date'].toString()),
      selectedTechStack: (json['selected_tech_stack'] ?? '').toString(),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.tryParse(json['completed_at'].toString()),
      title: (challenge['title'] ?? '').toString(),
      description: (challenge['description'] ?? '').toString(),
      difficulty: (challenge['difficulty'] ?? 'easy').toString(),
      techStack: (challenge['tech_stack'] ?? 'General').toString(),
      pointsReward: (challenge['points_reward'] as num? ?? 20).toInt(),
    );
  }
}

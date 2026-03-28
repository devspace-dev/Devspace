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
  final String missionType;
  final String question;
  final List<String> options;
  final String link;
  final bool isCorrect;

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
    required this.missionType,
    required this.question,
    required this.options,
    required this.link,
    required this.isCorrect,
  });

  bool get isCodingMission => missionType == 'coding';
  bool get isMcqMission => missionType == 'mcq';
  bool get isOneWordMission => missionType == 'oneword';

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    final mission = Map<String, dynamic>.from(
      (json['mission'] as Map?) ?? (json['challenge'] as Map?) ?? const {},
    );
    final missionType = (mission['type'] ?? 'coding').toString();
    final options = (mission['options'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final question = (mission['question'] ?? mission['description'] ?? '')
        .toString();

    return DailyChallengeModel(
      assignmentId: (json['id'] ?? '').toString(),
      challengeId: (json['mission_id'] ?? json['challenge_id'] ?? mission['id'] ?? '')
          .toString(),
      assignedDate: json['assigned_date'] == null
          ? null
          : DateTime.tryParse(json['assigned_date'].toString()),
      selectedTechStack: (json['selected_tech_stack'] ?? '').toString(),
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.tryParse(json['completed_at'].toString()),
      title: (mission['title'] ?? '').toString(),
      description: question,
      difficulty: _difficultyForMissionType(missionType),
      techStack: (mission['tech_stack'] ?? 'General').toString(),
      pointsReward: (mission['points_reward'] as num? ?? 20).toInt(),
      missionType: missionType,
      question: question,
      options: options,
      link: (mission['link'] ?? '').toString(),
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  static String _difficultyForMissionType(String missionType) {
    switch (missionType) {
      case 'mcq':
        return 'medium';
      case 'oneword':
        return 'easy';
      case 'coding':
      default:
        return 'hard';
    }
  }
}

class AuraBadgeModel {
  final String key;
  final String name;
  final DateTime? awardedAt;

  const AuraBadgeModel({
    required this.key,
    required this.name,
    this.awardedAt,
  });

  factory AuraBadgeModel.fromJson(Map<String, dynamic> json) {
    return AuraBadgeModel(
      key: (json['key'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      awardedAt: json['awardedAt'] == null
          ? null
          : DateTime.tryParse(json['awardedAt'].toString()),
    );
  }
}

class AuraSummaryModel {
  final String userId;
  final int auraPoints;
  final String level;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastChallengeCompletedOn;
  final List<AuraBadgeModel> badges;

  const AuraSummaryModel({
    required this.userId,
    required this.auraPoints,
    required this.level,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastChallengeCompletedOn,
    required this.badges,
  });

  factory AuraSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List? ?? const [];
    final lastCompletedStr = json['lastChallengeCompletedOn']?.toString();
    final lastCompleted = lastCompletedStr != null ? DateTime.tryParse(lastCompletedStr) : null;
    
    int currentStreak = (json['currentStreak'] as num? ?? 0).toInt();
    int longestStreak = (json['longestStreak'] as num? ?? 0).toInt();

    // Reset streak if more than 1 day has passed
    if (currentStreak > 0 && lastCompleted != null) {
      final today = DateTime.now();
      final lastDate = DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      
      final difference = todayDate.difference(lastDate).inDays;
      if (difference > 1) {
        currentStreak = 0;
      }
    }

    return AuraSummaryModel(
      userId: (json['userId'] ?? '').toString(),
      auraPoints: (json['auraPoints'] as num? ?? 0).toInt(),
      level: (json['level'] ?? 'Beginner').toString(),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastChallengeCompletedOn: lastCompleted,
      badges: rawBadges
          .map((badge) => AuraBadgeModel.fromJson(
                Map<String, dynamic>.from(badge as Map),
              ))
          .toList(),
    );
  }
}

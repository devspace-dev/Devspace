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

    return AuraSummaryModel(
      userId: (json['userId'] ?? '').toString(),
      auraPoints: (json['auraPoints'] as num? ?? 0).toInt(),
      level: (json['level'] ?? 'Beginner').toString(),
      currentStreak: (json['currentStreak'] as num? ?? 0).toInt(),
      longestStreak: (json['longestStreak'] as num? ?? 0).toInt(),
      lastChallengeCompletedOn: json['lastChallengeCompletedOn'] == null
          ? null
          : DateTime.tryParse(json['lastChallengeCompletedOn'].toString()),
      badges: rawBadges
          .map((badge) => AuraBadgeModel.fromJson(
                Map<String, dynamic>.from(badge as Map),
              ))
          .toList(),
    );
  }
}

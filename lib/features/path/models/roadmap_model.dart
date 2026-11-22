/// Core data models for the redesigned Path roadmap engine.
///
/// Designed to support:
/// - Exact finish-date calculations (`estimatedHours` / `weeklyHours`)
/// - Starting level skipping (`foundation` tags skipped in UI without fake DB rows)
/// - Interactive canvas & accessible vertical list views
/// - Direct "Practice this" navigation to matching quiz lobbies

enum RoadmapLevel {
  beginner,
  basics,
  comfortable;

  String get label {
    switch (this) {
      case RoadmapLevel.beginner:
        return 'Beginner';
      case RoadmapLevel.basics:
        return 'Some basics';
      case RoadmapLevel.comfortable:
        return 'Comfortable';
    }
  }

  String get description {
    switch (this) {
      case RoadmapLevel.beginner:
        return 'Start from scratch. Includes all foundation topics.';
      case RoadmapLevel.basics:
        return 'Skip syntax primers and jump into real building.';
      case RoadmapLevel.comfortable:
        return 'Fast-track to advanced patterns and production tooling.';
    }
  }
}

class VerifiedResource {
  final String title;
  final String sourceDomain;
  final String url;
  final String type;

  const VerifiedResource({
    required this.title,
    required this.sourceDomain,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'sourceDomain': sourceDomain,
        'url': url,
        'type': type,
      };

  factory VerifiedResource.fromJson(Map<String, dynamic> json) =>
      VerifiedResource(
        title: json['title'] as String,
        sourceDomain: json['sourceDomain'] as String,
        url: json['url'] as String,
        type: json['type'] as String,
      );
}

class RoadmapNode {
  final String id;
  final String title;
  final String why;
  final List<String> subtopics;
  final int estimatedHours;
  final List<String> prerequisites;
  final Set<String> tags;
  final String projectIdea;
  final List<VerifiedResource> resources;
  final String? practiceTier; // 'noob', 'script_kiddie', 'hacker', 'god'
  final DateTime lastReviewed;

  const RoadmapNode({
    required this.id,
    required this.title,
    required this.why,
    required this.subtopics,
    required this.estimatedHours,
    this.prerequisites = const [],
    this.tags = const {},
    required this.projectIdea,
    this.resources = const [],
    this.practiceTier,
    required this.lastReviewed,
  });

  bool get isFoundation => tags.contains('foundation');

  bool isSkippedForLevel(RoadmapLevel level) {
    if (level == RoadmapLevel.beginner) return false;
    return isFoundation;
  }
}

class RoadmapStage {
  final String id;
  final String title;
  final String description;
  final List<RoadmapNode> nodes;

  const RoadmapStage({
    required this.id,
    required this.title,
    required this.description,
    required this.nodes,
  });
}

class Roadmap {
  final String id;
  final String title;
  final String outcome;
  final String levelTag;
  final List<String> aliases;
  final List<RoadmapStage> stages;

  const Roadmap({
    required this.id,
    required this.title,
    required this.outcome,
    required this.levelTag,
    required this.aliases,
    required this.stages,
  });

  List<RoadmapNode> get allNodes => stages.expand((s) => s.nodes).toList();

  int get totalNodes => allNodes.length;

  int get totalHours =>
      allNodes.fold(0, (sum, node) => sum + node.estimatedHours);

  Set<String> get foundationNodeIds => allNodes
      .where((n) => n.isFoundation)
      .map((n) => n.id)
      .toSet();

  /// List of nodes that require student completion at [level].
  List<RoadmapNode> activeNodesForLevel(RoadmapLevel level) {
    if (level == RoadmapLevel.beginner) return allNodes;
    return allNodes.where((n) => !n.isFoundation).toList();
  }

  /// Calculates total remaining hours needed based on starting level and completed nodes.
  int remainingHours({
    required RoadmapLevel level,
    required Set<String> completedNodeIds,
  }) {
    final activeNodes = activeNodesForLevel(level);
    int remaining = 0;
    for (final node in activeNodes) {
      if (!completedNodeIds.contains(node.id)) {
        remaining += node.estimatedHours;
      }
    }
    return remaining;
  }

  /// Estimated finish time in weeks based on weekly study commitment (3, 6, or 10 hours).
  int estimatedWeeks({
    required RoadmapLevel level,
    required int weeklyHours,
    required Set<String> completedNodeIds,
  }) {
    final rem = remainingHours(
      level: level,
      completedNodeIds: completedNodeIds,
    );
    if (rem <= 0) return 0;
    final hrs = weeklyHours <= 0 ? 6 : weeklyHours;
    return (rem / hrs).ceil();
  }

  /// Progress percentage (0.0 to 1.0) taking into account skipped foundation nodes.
  double progressPercent({
    required RoadmapLevel level,
    required Set<String> completedNodeIds,
  }) {
    final activeNodes = activeNodesForLevel(level);
    if (activeNodes.isEmpty) return 1.0;

    int completedCount = 0;
    for (final node in activeNodes) {
      if (completedNodeIds.contains(node.id)) {
        completedCount++;
      }
    }
    return (completedCount / activeNodes.length).clamp(0.0, 1.0);
  }

  /// Returns true if search query matches title, aliases, or any stage description.
  bool matchesQuery(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    if (title.toLowerCase().contains(clean)) return true;
    if (outcome.toLowerCase().contains(clean)) return true;
    if (id.toLowerCase().contains(clean)) return true;

    for (final alias in aliases) {
      if (alias.toLowerCase().contains(clean)) return true;
    }
    for (final s in stages) {
      if (s.title.toLowerCase().contains(clean)) return true;
      for (final n in s.nodes) {
        if (n.title.toLowerCase().contains(clean)) return true;
      }
    }
    return false;
  }
}

/// Representation of a user's selection stored in `public.user_roadmaps`.
class UserRoadmapSelection {
  final String id;
  final String userId;
  final String roadmapId;
  final String status; // 'active' or 'saved'
  final RoadmapLevel level;
  final int weeklyHours; // 3, 6, 10
  final DateTime startedAt;
  final DateTime updatedAt;

  const UserRoadmapSelection({
    required this.id,
    required this.userId,
    required this.roadmapId,
    required this.status,
    required this.level,
    required this.weeklyHours,
    required this.startedAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory UserRoadmapSelection.fromJson(Map<String, dynamic> json) {
    final lvlStr = (json['level'] ?? 'beginner').toString().toLowerCase();
    RoadmapLevel lvl = RoadmapLevel.beginner;
    if (lvlStr == 'basics' || lvlStr == 'some basics') {
      lvl = RoadmapLevel.basics;
    } else if (lvlStr == 'comfortable') {
      lvl = RoadmapLevel.comfortable;
    }

    return UserRoadmapSelection(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      roadmapId: (json['roadmap_id'] ?? '').toString(),
      status: (json['status'] ?? 'saved').toString(),
      level: lvl,
      weeklyHours: (json['weekly_hours'] as num?)?.toInt() ?? 6,
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'roadmap_id': roadmapId,
        'status': status,
        'level': level.name,
        'weekly_hours': weeklyHours,
        'started_at': startedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:devspace/features/path/models/roadmap_model.dart';
import 'package:devspace/features/path/data/curated_roadmaps.dart';

void main() {
  group('RoadmapLevel tests', () {
    test('provides student-friendly labels and descriptions', () {
      expect(RoadmapLevel.beginner.label, 'Beginner');
      expect(RoadmapLevel.basics.label, 'Some basics');
      expect(RoadmapLevel.comfortable.label, 'Comfortable');

      expect(RoadmapLevel.beginner.description, contains('foundation'));
      expect(RoadmapLevel.basics.description, contains('Skip syntax primers'));
      expect(RoadmapLevel.comfortable.description, contains('Fast-track'));
    });
  });

  group('Roadmap model calculation tests', () {
    test('Flutter roadmap total hours and node counts', () {
      expect(kFlutterRoadmap.stages.length, 5);
      expect(kFlutterRoadmap.allNodes.length, 10);
      expect(kFlutterRoadmap.totalNodes, 10);
      expect(kFlutterRoadmap.totalHours, 92);
    });

    test('Foundation node filtering by starting level', () {
      final foundationNodes = kFlutterRoadmap.foundationNodeIds;
      expect(foundationNodes, contains('fl_dart_basics'));
      expect(foundationNodes, contains('fl_oop_patterns'));
      expect(foundationNodes.length, 2);

      // Beginner gets all 10 nodes
      final beginnerNodes = kFlutterRoadmap.activeNodesForLevel(RoadmapLevel.beginner);
      expect(beginnerNodes.length, 10);

      // Basics and Comfortable skip the 2 foundation nodes (8 nodes remaining)
      final basicsNodes = kFlutterRoadmap.activeNodesForLevel(RoadmapLevel.basics);
      expect(basicsNodes.length, 8);
      expect(basicsNodes.any((n) => n.id == 'fl_dart_basics'), isFalse);
      expect(basicsNodes.any((n) => n.id == 'fl_oop_patterns'), isFalse);

      final comfortableNodes = kFlutterRoadmap.activeNodesForLevel(RoadmapLevel.comfortable);
      expect(comfortableNodes.length, 8);
    });

    test('Remaining hours calculation based on level and completed nodes', () {
      // Beginner with 0 completions: all 92h
      expect(
        kFlutterRoadmap.remainingHours(
          level: RoadmapLevel.beginner,
          completedNodeIds: {},
        ),
        92,
      );

      // Beginner after completing fl_dart_basics (10h): 82h
      expect(
        kFlutterRoadmap.remainingHours(
          level: RoadmapLevel.beginner,
          completedNodeIds: {'fl_dart_basics'},
        ),
        82,
      );

      // Basics starts by skipping fl_dart_basics (10h) + fl_oop_patterns (8h) = 18h skipped -> 74h
      expect(
        kFlutterRoadmap.remainingHours(
          level: RoadmapLevel.basics,
          completedNodeIds: {},
        ),
        74,
      );

      // Basics after completing fl_widgets_layout (10h): 64h
      expect(
        kFlutterRoadmap.remainingHours(
          level: RoadmapLevel.basics,
          completedNodeIds: {'fl_widgets_layout'},
        ),
        64,
      );
    });

    test('Estimated weeks calculation with 3h, 6h, and 10h commitments', () {
      // 92h total for beginner:
      // at 3h/wk -> ceil(92/3) = 31 weeks
      // at 6h/wk -> ceil(92/6) = 16 weeks
      // at 10h/wk -> ceil(92/10) = 10 weeks
      expect(
        kFlutterRoadmap.estimatedWeeks(
          level: RoadmapLevel.beginner,
          weeklyHours: 3,
          completedNodeIds: {},
        ),
        31,
      );
      expect(
        kFlutterRoadmap.estimatedWeeks(
          level: RoadmapLevel.beginner,
          weeklyHours: 6,
          completedNodeIds: {},
        ),
        16,
      );
      expect(
        kFlutterRoadmap.estimatedWeeks(
          level: RoadmapLevel.beginner,
          weeklyHours: 10,
          completedNodeIds: {},
        ),
        10,
      );

      // For Basics (74h):
      // at 6h/wk -> ceil(74/6) = 13 weeks
      expect(
        kFlutterRoadmap.estimatedWeeks(
          level: RoadmapLevel.basics,
          weeklyHours: 6,
          completedNodeIds: {},
        ),
        13,
      );

      // All nodes completed -> 0 weeks
      final allNodeIds = kFlutterRoadmap.allNodes.map((n) => n.id).toSet();
      expect(
        kFlutterRoadmap.estimatedWeeks(
          level: RoadmapLevel.beginner,
          weeklyHours: 6,
          completedNodeIds: allNodeIds,
        ),
        0,
      );
    });

    test('Progress percentage calculation', () {
      // Beginner: 0/10 = 0.0
      expect(
        kFlutterRoadmap.progressPercent(
          level: RoadmapLevel.beginner,
          completedNodeIds: {},
        ),
        0.0,
      );

      // Beginner: 5/10 = 0.5
      final halfIds = kFlutterRoadmap.allNodes.take(5).map((n) => n.id).toSet();
      expect(
        kFlutterRoadmap.progressPercent(
          level: RoadmapLevel.beginner,
          completedNodeIds: halfIds,
        ),
        0.5,
      );

      // Basics: 8 active nodes. 4 completed = 0.5
      final basicsActive = kFlutterRoadmap.activeNodesForLevel(RoadmapLevel.basics);
      final fourBasicsIds = basicsActive.take(4).map((n) => n.id).toSet();
      expect(
        kFlutterRoadmap.progressPercent(
          level: RoadmapLevel.basics,
          completedNodeIds: fourBasicsIds,
        ),
        0.5,
      );
    });

    test('Search matching on title, aliases, and subtopics', () {
      expect(kFlutterRoadmap.matchesQuery('flutter'), isTrue);
      expect(kFlutterRoadmap.matchesQuery('FLUTTER'), isTrue);
      // Aliases
      expect(kFlutterRoadmap.matchesQuery('ios'), isTrue);
      expect(kFlutterRoadmap.matchesQuery('android'), isTrue);
      expect(kFlutterRoadmap.matchesQuery('mobile'), isTrue);
      expect(kFlutterRoadmap.matchesQuery('dart'), isTrue);
      // Node title
      expect(kFlutterRoadmap.matchesQuery('Null Safety'), isTrue);
      // Non matching
      expect(kFlutterRoadmap.matchesQuery('kubernetes'), isFalse);
    });
  });

  group('UserRoadmapSelection model tests', () {
    test('Serialization and deserialization with level parsing', () {
      final json = {
        'id': 'select-123',
        'user_id': 'user-456',
        'roadmap_id': 'flutter',
        'status': 'active',
        'level': 'basics',
        'weekly_hours': 10,
        'started_at': '2026-11-22T10:00:00.000Z',
        'updated_at': '2026-11-22T12:00:00.000Z',
      };

      final selection = UserRoadmapSelection.fromJson(json);
      expect(selection.id, 'select-123');
      expect(selection.userId, 'user-456');
      expect(selection.roadmapId, 'flutter');
      expect(selection.status, 'active');
      expect(selection.isActive, isTrue);
      expect(selection.level, RoadmapLevel.basics);
      expect(selection.weeklyHours, 10);

      final outJson = selection.toJson();
      expect(outJson['roadmap_id'], 'flutter');
      expect(outJson['level'], 'basics');
      expect(outJson['weekly_hours'], 10);
      expect(outJson['status'], 'active');
    });

    test('Default fallbacks for null or missing values', () {
      final selection = UserRoadmapSelection.fromJson({});
      expect(selection.status, 'saved');
      expect(selection.isActive, isFalse);
      expect(selection.level, RoadmapLevel.beginner);
      expect(selection.weeklyHours, 6);
    });
  });

  group('Curated Content Integrity: Flutter & Web tracks', () {
    test('Flutter roadmap content is complete and well-structured', () {
      expect(kFlutterRoadmap.id, 'flutter');
      expect(kFlutterRoadmap.title, isNotEmpty);
      expect(kFlutterRoadmap.outcome, isNotEmpty);

      for (final stage in kFlutterRoadmap.stages) {
        expect(stage.id, isNotEmpty);
        expect(stage.title, isNotEmpty);
        expect(stage.description, isNotEmpty);
        expect(stage.nodes, isNotEmpty);

        for (final node in stage.nodes) {
          expect(node.id, isNotEmpty);
          expect(node.title, isNotEmpty);
          expect(node.why.length, greaterThan(30), reason: 'Node ${node.id} why should explain significance');
          expect(node.subtopics.length, greaterThanOrEqualTo(3), reason: 'Node ${node.id} should have >= 3 subtopics');
          expect(node.projectIdea, isNotEmpty, reason: 'Node ${node.id} should have a practical project');
          expect(node.estimatedHours, greaterThan(0));

          // Rule 9 verification: if resources are present, they must be HTTPS
          for (final res in node.resources) {
            expect(res.url, startsWith('https://'));
            expect(res.sourceDomain, isNotEmpty);
            expect(res.title, isNotEmpty);
          }
        }
      }
    });

    test('Web Frontend roadmap content is complete and well-structured', () {
      expect(kWebRoadmap.id, 'web');
      expect(kWebRoadmap.title, 'Web Frontend Developer');
      expect(kWebRoadmap.stages.length, 4);
      expect(kWebRoadmap.allNodes.length, 10);
      expect(kWebRoadmap.totalHours, 94);

      // Verify aliases
      expect(kWebRoadmap.matchesQuery('react'), isTrue);
      expect(kWebRoadmap.matchesQuery('frontend'), isTrue);
      expect(kWebRoadmap.matchesQuery('javascript'), isTrue);

      // Verify foundation nodes
      final foundation = kWebRoadmap.foundationNodeIds;
      expect(foundation, contains('web_html_css'));
      expect(foundation, contains('web_js_core'));
      expect(foundation.length, 2);

      for (final stage in kWebRoadmap.stages) {
        for (final node in stage.nodes) {
          expect(node.id, isNotEmpty);
          expect(node.title, isNotEmpty);
          expect(node.why.length, greaterThan(30));
          expect(node.subtopics.length, greaterThanOrEqualTo(3));
          expect(node.projectIdea, isNotEmpty);
          expect(node.estimatedHours, greaterThan(0));

          for (final res in node.resources) {
            expect(res.url, startsWith('https://'));
            expect(res.sourceDomain, isNotEmpty);
            expect(res.title, isNotEmpty);
          }
        }
      }
    });

    test('Text-only guidance nodes have empty resources (Rule 9 compliance)', () {
      // These nodes intentionally omit external unverified blogs in favor of self-contained guidance:
      final flutterCleanArch = kFlutterRoadmap.allNodes.firstWhere((n) => n.id == 'fl_clean_arch');
      expect(flutterCleanArch.resources, isEmpty);
      expect(flutterCleanArch.why, contains('Spaghetti code'));

      final webRouting = kWebRoadmap.allNodes.firstWhere((n) => n.id == 'web_react_routing');
      expect(webRouting.resources, isEmpty);
      expect(webRouting.why, contains('Multi-page feel'));
    });
  });
}

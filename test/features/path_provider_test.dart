import 'package:flutter_test/flutter_test.dart';
import 'package:devspace/features/path/models/roadmap_model.dart';
import 'package:devspace/features/path/providers/path_provider.dart';

void main() {
  group('PathProvider state management & calculations', () {
    test('initial state has default curated roadmaps and no active roadmap', () {
      final provider = PathProvider(
        currentUserIdGetter: () => null,
      );

      expect(provider.allRoadmaps.length, 5);
      expect(provider.activeRoadmap, isNull);
      expect(provider.hasActiveRoadmap, isFalse);
      expect(provider.activeSelection, isNull);
      expect(provider.savedSelections, isEmpty);
      expect(provider.completedNodeIds, isEmpty);
      expect(provider.remainingHours, 0);
      expect(provider.estimatedWeeks, 0);
      expect(provider.progressPercent, 0.0);
      expect(provider.nextRecommendedStep, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('loadUserRoadmaps populates active roadmap and completed node progress', () async {
      final fakeSelections = [
        UserRoadmapSelection(
          id: 'sel_1',
          userId: 'user_123',
          roadmapId: 'flutter',
          status: 'active',
          level: RoadmapLevel.beginner,
          weeklyHours: 6,
          startedAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
        ),
        UserRoadmapSelection(
          id: 'sel_2',
          userId: 'user_123',
          roadmapId: 'web',
          status: 'saved',
          level: RoadmapLevel.basics,
          weeklyHours: 10,
          startedAt: DateTime(2026, 11, 15),
          updatedAt: DateTime(2026, 11, 15),
        ),
      ];

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async {
          if (roadmapId == 'flutter') {
            return {'fl_dart_basics'}; // 10h completed
          }
          return {};
        },
      );

      await provider.loadUserRoadmaps();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.hasActiveRoadmap, isTrue);
      expect(provider.activeRoadmap?.id, 'flutter');
      expect(provider.savedSelections.length, 1);
      expect(provider.savedSelections.first.roadmapId, 'web');

      // 10h completed out of 92h total -> 82h remaining
      // At 6h/week commitment -> ceil(82/6) = 14 weeks
      expect(provider.completedNodeIds, {'fl_dart_basics'});
      expect(provider.remainingHours, 82);
      expect(provider.estimatedWeeks, 14);
      expect(provider.completedActiveCount, 1);
      expect(provider.totalActiveCount, 10);
      expect(provider.progressPercent, 0.1);

      // Next recommended step is fl_oop_patterns (first incomplete node)
      expect(provider.nextRecommendedStep?.id, 'fl_oop_patterns');
    });

    test('starting level skipping adjusts remaining hours and next recommended step', () async {
      final fakeSelections = [
        UserRoadmapSelection(
          id: 'sel_1',
          userId: 'user_123',
          roadmapId: 'flutter',
          status: 'active',
          level: RoadmapLevel.basics, // Skips fl_dart_basics (10h) & fl_oop_patterns (8h)
          weeklyHours: 10,
          startedAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
        ),
      ];

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async => {},
      );

      await provider.loadUserRoadmaps();

      // Total active nodes for basics is 8 (10 - 2 foundation nodes)
      // Total hours remaining is 92 - 18 = 74h
      // At 10h/week -> ceil(74/10) = 8 weeks
      expect(provider.currentLevel, RoadmapLevel.basics);
      expect(provider.totalActiveCount, 8);
      expect(provider.remainingHours, 74);
      expect(provider.estimatedWeeks, 8);

      // The next recommended step should skip foundation nodes and recommend fl_widget_tree
      expect(provider.nextRecommendedStep?.id, 'fl_widget_tree');
    });

    test('selectRoadmap demotes previous active roadmap to saved and loads new progress', () async {
      var activatorCalled = false;
      String? demotedPrevId;

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => [
          UserRoadmapSelection(
            id: 'sel_1',
            userId: 'user_123',
            roadmapId: 'flutter',
            status: 'active',
            level: RoadmapLevel.beginner,
            weeklyHours: 6,
            startedAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
          ),
        ],
        roadmapProgressLoader: (userId, roadmapId) async {
          if (roadmapId == 'backend') return {'be_http_rest'};
          return {'fl_dart_basics'};
        },
        roadmapActivator: ({
          required userId,
          required roadmapId,
          required level,
          required weeklyHours,
          previousActiveRoadmapId,
        }) async {
          activatorCalled = true;
          demotedPrevId = previousActiveRoadmapId;
          return true;
        },
      );

      await provider.loadUserRoadmaps();
      expect(provider.activeRoadmap?.id, 'flutter');

      // Now activate Backend track
      final ok = await provider.selectRoadmap(
        roadmapId: 'backend',
        level: RoadmapLevel.basics,
        weeklyHours: 10,
      );

      expect(ok, isTrue);
      expect(activatorCalled, isTrue);
      expect(demotedPrevId, 'flutter');

      // Active is now backend
      expect(provider.activeRoadmap?.id, 'backend');
      expect(provider.currentLevel, RoadmapLevel.basics);
      expect(provider.currentWeeklyHours, 10);

      // Flutter was demoted to saved
      expect(provider.savedSelections.any((s) => s.roadmapId == 'flutter'), isTrue);

      // Backend progress was loaded
      expect(provider.completedNodeIds, {'be_http_rest'});
    });

    test('optimistic node completion toggling updates immediately and syncs', () async {
      var togglerCalls = 0;

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => [
          UserRoadmapSelection(
            id: 'sel_1',
            userId: 'user_123',
            roadmapId: 'flutter',
            status: 'active',
            level: RoadmapLevel.beginner,
            weeklyHours: 6,
            startedAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
          ),
        ],
        roadmapProgressLoader: (userId, roadmapId) async => {},
        nodeCompletionToggler: ({
          required userId,
          required roadmapId,
          required nodeId,
          required completed,
        }) async {
          togglerCalls++;
          return true;
        },
      );

      await provider.loadUserRoadmaps();
      expect(provider.completedNodeIds, isEmpty);

      // Complete fl_dart_basics
      final ok = await provider.toggleNodeCompletion(
        roadmapId: 'flutter',
        nodeId: 'fl_dart_basics',
      );

      expect(ok, isTrue);
      expect(togglerCalls, 1);
      expect(provider.completedNodeIds, contains('fl_dart_basics'));

      // Uncomplete fl_dart_basics
      final uncompleteOk = await provider.toggleNodeCompletion(
        roadmapId: 'flutter',
        nodeId: 'fl_dart_basics',
      );

      expect(uncompleteOk, isTrue);
      expect(togglerCalls, 2);
      expect(provider.completedNodeIds, isEmpty);
    });

    test('optimistic node completion rolls back on server failure', () async {
      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => [
          UserRoadmapSelection(
            id: 'sel_1',
            userId: 'user_123',
            roadmapId: 'flutter',
            status: 'active',
            level: RoadmapLevel.beginner,
            weeklyHours: 6,
            startedAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
          ),
        ],
        roadmapProgressLoader: (userId, roadmapId) async => {},
        nodeCompletionToggler: ({
          required userId,
          required roadmapId,
          required nodeId,
          required completed,
        }) async {
          // Simulate database error or RLS rejection
          return false;
        },
      );

      await provider.loadUserRoadmaps();
      expect(provider.completedNodeIds, isEmpty);

      // Attempt to complete a node
      final ok = await provider.toggleNodeCompletion(
        roadmapId: 'flutter',
        nodeId: 'fl_dart_basics',
      );

      // Must report failure, rollback local state, and set an error message
      expect(ok, isFalse);
      expect(provider.completedNodeIds, isEmpty);
      expect(provider.errorMessage, contains('Could not sync node completion. Reverted.'));
    });

    test('toggleNodeCompletion rejects completing locked nodes without prerequisites', () async {
      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => [
          UserRoadmapSelection(
            id: 'sel_1',
            userId: 'user_123',
            roadmapId: 'flutter',
            status: 'active',
            level: RoadmapLevel.beginner,
            weeklyHours: 6,
            startedAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
          ),
        ],
        roadmapProgressLoader: (userId, roadmapId) async => {},
      );

      await provider.loadUserRoadmaps();
      expect(provider.completedNodeIds, isEmpty);

      // Attempt to complete fl_oop_patterns (which requires fl_dart_basics)
      final ok = await provider.toggleNodeCompletion(
        roadmapId: 'flutter',
        nodeId: 'fl_oop_patterns',
      );

      expect(ok, isFalse);
      expect(provider.completedNodeIds, isEmpty);
      expect(provider.errorMessage, contains('Complete previous topic'));
    });

    test('updateActiveSettings updates hours and rolls back if update fails', () async {
      var failUpdate = false;

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => [
          UserRoadmapSelection(
            id: 'sel_1',
            userId: 'user_123',
            roadmapId: 'flutter',
            status: 'active',
            level: RoadmapLevel.beginner,
            weeklyHours: 6,
            startedAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
          ),
        ],
        roadmapProgressLoader: (userId, roadmapId) async => {},
        settingsUpdater: ({
          required userId,
          required roadmapId,
          required level,
          required weeklyHours,
        }) async {
          return !failUpdate;
        },
      );

      await provider.loadUserRoadmaps();
      expect(provider.currentWeeklyHours, 6);

      // Successful update to 10h/wk
      final ok = await provider.updateActiveSettings(
        level: RoadmapLevel.beginner,
        weeklyHours: 10,
      );
      expect(ok, isTrue);
      expect(provider.currentWeeklyHours, 10);

      // Failed update rolls back to 10h/wk
      failUpdate = true;
      final failedOk = await provider.updateActiveSettings(
        level: RoadmapLevel.comfortable,
        weeklyHours: 3,
      );
      expect(failedOk, isFalse);
      expect(provider.currentWeeklyHours, 10);
      expect(provider.currentLevel, RoadmapLevel.beginner);
      expect(provider.errorMessage, contains('Could not update roadmap settings'));
    });

    test('search filtering and clearError', () {
      final provider = PathProvider(
        currentUserIdGetter: () => null,
      );

      // Search matching alias 'react'
      provider.setSearchQuery('react');
      expect(provider.searchQuery, 'react');
      expect(provider.filteredRoadmaps.length, 1);
      expect(provider.filteredRoadmaps.first.id, 'web');

      // Empty query shows all 5
      provider.setSearchQuery('');
      expect(provider.filteredRoadmaps.length, 5);

      // Search 'dsa'
      provider.setSearchQuery('leetcode');
      expect(provider.filteredRoadmaps.length, 1);
      expect(provider.filteredRoadmaps.first.id, 'dsa');
    });
  });
}

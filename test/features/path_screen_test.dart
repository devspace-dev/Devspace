import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/features/path/data/curated_roadmaps.dart';
import 'package:devspace/features/path/models/roadmap_model.dart';
import 'package:devspace/features/path/providers/path_provider.dart';
import 'package:devspace/features/path/screens/path_screen.dart';
import 'package:devspace/features/path/widgets/path_active_view.dart';
import 'package:devspace/features/path/widgets/path_find_view.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createPathApp(PathProvider provider) {
    return ChangeNotifierProvider<PathProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: PathScreen(),
      ),
    );
  }

  group('PathScreen & UI widget tests', () {
    testWidgets('renders PathFindView when user has no active roadmap', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = PathProvider(
        currentUserIdGetter: () => null,
      );

      await tester.pumpWidget(createPathApp(provider));
      await tester.pumpAndSettle();

      expect(find.byType(PathFindView), findsOneWidget);
      expect(find.text('CHOOSE YOUR GOAL'), findsOneWidget);
      expect(find.text('FLUTTER APP DEVELOPER'), findsOneWidget);
      expect(find.text('WEB FRONTEND (HTML/CSS/JS/REACT)'), findsOneWidget);
      expect(find.text('BACKEND & SYSTEMS ENGINEERING'), findsOneWidget);
    });

    testWidgets('search field filters curated roadmaps in real time', (tester) async {
      final provider = PathProvider(
        currentUserIdGetter: () => null,
      );

      await tester.pumpWidget(createPathApp(provider));
      await tester.pumpAndSettle();

      // Enter search query 'leetcode'
      await tester.enterText(find.byType(TextField), 'leetcode');
      await tester.pumpAndSettle();

      // Only DSA roadmap should match
      expect(find.text('DATA STRUCTURES, ALGORITHMS & PLACEMENTS'), findsOneWidget);
      expect(find.text('FLUTTER APP DEVELOPER'), findsNothing);
    });

    testWidgets('renders PathActiveView when user has an active roadmap', (tester) async {
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
      ];

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async => {'fl_dart_basics'},
      );

      await provider.loadUserRoadmaps();

      await tester.pumpWidget(createPathApp(provider));
      await tester.pumpAndSettle();

      expect(find.byType(PathActiveView), findsOneWidget);
      expect(find.text('FLUTTER APP DEVELOPER'), findsOneWidget);
      expect(find.text('CONTINUE LEARNING'), findsOneWidget);
      expect(find.text('DART SYNTAX & NULL SAFETY'), findsOneWidget);
      expect(find.text('OOP, RECORDS & PATTERN MATCHING'), findsWidgets);

      // Verify One Clear Next Step points to fl_oop_patterns
      expect(provider.nextRecommendedStep?.id, 'fl_oop_patterns');
    });

    testWidgets('tapping explore button switches to PathFindView with active banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
      ];

      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async => {},
      );

      await provider.loadUserRoadmaps();

      await tester.pumpWidget(createPathApp(provider));
      await tester.pumpAndSettle();

      // Tap browse all roadmaps icon
      await tester.tap(find.byTooltip('Browse all roadmaps'));
      await tester.pumpAndSettle();

      expect(find.byType(PathFindView), findsOneWidget);
      expect(find.textContaining('CURRENTLY ACTIVE: FLUTTER APP DEVELOPER'), findsOneWidget);

      // Tap VIEW ROUTE to return to PathActiveView
      await tester.tap(find.text('VIEW ROUTE'));
      await tester.pumpAndSettle();

      expect(find.byType(PathActiveView), findsOneWidget);
    });

    testWidgets('tapping a locked node allows user to view syllabus but shows locked completion button', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
      ];

      // No nodes completed yet
      final provider = PathProvider(
        currentUserIdGetter: () => 'user_123',
        userRoadmapsLoader: (userId) async => fakeSelections,
        roadmapProgressLoader: (userId, roadmapId) async => {},
      );

      await provider.loadUserRoadmaps();

      await tester.pumpWidget(createPathApp(provider));
      await tester.pumpAndSettle();

      // Tap on fl_oop_patterns which is locked because fl_dart_basics is not completed
      await tester.tap(find.text('OOP, RECORDS & PATTERN MATCHING').last);
      await tester.pumpAndSettle();

      // Sheet opens and allows viewing content
      expect(find.text('WHY THIS MATTERS'), findsOneWidget);
      expect(find.text('KEY TOPICS TO MASTER'), findsOneWidget);
      expect(find.text('PRACTICE PROJECT IDEA'), findsOneWidget);

      // Button is locked and shows prerequisite requirement
      expect(find.text('TOPIC LOCKED'), findsOneWidget);
      expect(find.textContaining('Complete "Dart Syntax & Null Safety" first to unlock.'), findsOneWidget);
    });
  });
}

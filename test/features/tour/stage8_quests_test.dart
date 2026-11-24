import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/features/play/screens/play_screen.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/widgets/first_quests_card.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/posts_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TourAnchorRegistry.instance.clear();
  });

  UserModel makeUser({
    String id = 'test-builder',
    String name = 'Builder Bob',
    int aura = 0,
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: 'builderbob',
      email: 'bob@example.com',
      avatar: '',
      color: Colors.blue,
      aura: aura,
      roles: const ['Student'],
      year: '2nd Year',
      branch: 'CSE',
      building: 'Block B',
      stack: const ['Flutter'],
      followers: 0,
      following: 0,
      bio: 'Building things',
      college: 'IIIT',
      githubHandle: 'builderbob',
      profileCompleted: true,
      currentStreak: 1,
    );
  }

  Widget buildQuestCardApp({
    UserModel? user,
    TourController? controller,
    bool? overridePathDone,
    bool? overrideSolveDone,
    bool? overridePostDone,
    bool? overrideEventDone,
    bool? overrideBadgeDone,
    bool showBadgeQuest = false,
    double fontScale = 1.0,
    Size screenSize = const Size(360, 640),
  }) {
    final effectiveUser = user ?? makeUser();
    final effectiveController = controller ?? TourController();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: effectiveUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            initialPosts: const [],
            postsPageLoader: ({required limit, required offset}) async => const [],
          ),
        ),
        ChangeNotifierProvider<TourController>.value(value: effectiveController),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              textScaler: TextScaler.linear(fontScale),
            ),
            child: SingleChildScrollView(
              child: FirstQuestsCard(
                overridePathDone: overridePathDone,
                overrideSolveDone: overrideSolveDone,
                overridePostDone: overridePostDone,
                overrideEventDone: overrideEventDone,
                overrideBadgeDone: overrideBadgeDone,
                showBadgeQuest: showBadgeQuest,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Stage 8: First Quests Card (S8)', () {
    testWidgets('Renders 4 starter quests with 0/4 progress when fresh', (tester) async {
      await tester.pumpWidget(buildQuestCardApp());
      await tester.pumpAndSettle();

      expect(find.text('FIRST QUESTS'), findsOneWidget);
      expect(find.text('0/4'), findsOneWidget);
      expect(find.text('Pick your path'), findsOneWidget);
      expect(find.text('Solve your first question'), findsOneWidget);
      expect(find.text('+5 AURA'), findsOneWidget);
      expect(find.text('Make your first post'), findsOneWidget);
      expect(find.text('Find an event'), findsOneWidget);
    });

    testWidgets('Derives "Pick your path" completion status (1/4)', (tester) async {
      await tester.pumpWidget(buildQuestCardApp(overridePathDone: true));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
      // Radio uncheck icon is used for incomplete quests; checked icon for completed
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(3));
    });

    testWidgets('Derives "Solve your first question" completion status (1/4)', (tester) async {
      await tester.pumpWidget(buildQuestCardApp(overrideSolveDone: true));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
      // When solved, +5 AURA reward tag is hidden
      expect(find.text('+5 AURA'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Derives "Make your first post" completion status (1/4)', (tester) async {
      await tester.pumpWidget(buildQuestCardApp(overridePostDone: true));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Derives "Find an event" completion status (1/4)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'tour_v1_test-builder_completed': [TourStep.s5Events.name],
      });
      final controller = TourController();
      await controller.initForUser(userId: 'test-builder', isNewRegistration: false);

      await tester.pumpWidget(buildQuestCardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('1/4'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Renders 5th quest ("Earn your first badge") when badge feature is enabled', (tester) async {
      await tester.pumpWidget(buildQuestCardApp(showBadgeQuest: true));
      await tester.pumpAndSettle();

      expect(find.text('FIRST QUESTS'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Earn your first badge'), findsOneWidget);
    });

    testWidgets('Automatically disappears (SizedBox.shrink) when all quests are completed', (tester) async {
      await tester.pumpWidget(buildQuestCardApp(
        overridePathDone: true,
        overrideSolveDone: true,
        overridePostDone: true,
        overrideEventDone: true,
      ));
      await tester.pumpAndSettle();

      // Entire card disappears
      expect(find.text('FIRST QUESTS'), findsNothing);
      expect(find.text('Pick your path'), findsNothing);
      expect(find.byType(FirstQuestsCard), findsOneWidget);
    });

    testWidgets('Renders cleanly inside PlayScreen', (tester) async {
      final user = makeUser();
      final auth = AuthProvider(initialUser: user, listenToAuthChanges: false);
      final engagement = EngagementProvider();
      final controller = TourController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<EngagementProvider>.value(value: engagement),
            ChangeNotifierProvider<TourController>.value(value: controller),
          ],
          child: const MaterialApp(
            home: PlayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FIRST QUESTS'), findsOneWidget);
      expect(find.text('0/4'), findsOneWidget);
      expect(find.text('QUEUE UP'), findsOneWidget);
    });

    testWidgets('FirstQuestsCard renders without overflow under 200% font scale on 360dp width', (tester) async {
      final previousHandler = FlutterError.onError;
      FlutterErrorDetails? caughtError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
      };

      try {
        await tester.pumpWidget(buildQuestCardApp(
          fontScale: 2.0,
          screenSize: const Size(360, 640),
          showBadgeQuest: true,
        ));
        await tester.pumpAndSettle();

        expect(caughtError, isNull, reason: 'FirstQuestsCard overflowed under 200% text scale on 360dp');
        expect(find.text('FIRST QUESTS'), findsOneWidget);
      } finally {
        FlutterError.onError = previousHandler;
      }
    });
  });
}

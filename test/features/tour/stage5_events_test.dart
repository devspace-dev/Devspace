import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/features/community/screens/community_screen.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/tour_copy.dart';
import 'package:devspace/features/tour/widgets/coach_mark_overlay.dart';
import 'package:devspace/features/tour/widgets/tour_host.dart';
import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/models/post_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/messages_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/users_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late TourController tourController;

  final testUser = UserModel(
    id: 'u-tour-events-user',
    name: 'Builder Two',
    handle: 'builder2',
    email: 'builder2@example.com',
    avatar: '',
    color: Colors.black,
    aura: 100,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'Block B',
    stack: const ['Flutter', 'Dart'],
    followers: 10,
    following: 8,
    bio: '',
    college: 'IIIT',
    githubHandle: 'builder2',
    profileCompleted: true,
    currentStreak: 2,
  );

  final samplePost = PostModel(
    id: 'p-events-1',
    userId: 'other-user',
    content: 'Hackathon team forming now!',
    tags: const ['hackathon'],
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    likes: 3,
    comments: 2,
  );

  const sampleEvent = EventAccessModel(
    id: 'e-events-1',
    title: 'HackDev 2026',
    description: 'B.Tech Hackathon',
    requiredAura: 50,
    link: 'https://example.com/hackdev',
    type: 'hackathon',
    unlocked: true,
    locked: false,
    date: 'Dec 2026',
    organizer: 'DevSpace Community',
    location: 'Bengaluru',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
    TourAnchorRegistry.instance.clear();
  });

  Widget buildEventsTestApp({
    required TourController controller,
  }) {
    final msgP = MessagesProvider(
      conversationStreamLoader: (_) => Stream.value(const []),
      unreadCountsLoader: (_, __) async => const {},
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            initialPosts: [samplePost],
            postsPageLoader: ({required limit, required offset}) async => [samplePost],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: [testUser],
            usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async => [testUser],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider(
            eligibleEventsLoader: () async => [sampleEvent],
          ),
        ),
        ChangeNotifierProvider<MessagesProvider>.value(value: msgP),
        ChangeNotifierProvider<TourController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: TourHost(
            child: CommunityScreen(),
          ),
        ),
      ),
    );
  }

  group('Stage 5: Events Tab (S5)', () {
    testWidgets('S5 Coach mark renders spotlight on EVENTS tab and advances to S6 on NEXT tap', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'u-tour-events-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      // Advance through S1, S2, S3, S4 to S5
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      expect(tourController.currentStep, TourStep.s5Events);

      await tester.pumpWidget(buildEventsTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // S5 Coach mark is visible
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s5EventsTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s5EventsBody), findsOneWidget);

      // Verify mascot is rendered
      expect(
        find.descendant(
          of: find.byType(CoachMarkOverlay),
          matching: find.byType(Glitch),
        ),
        findsOneWidget,
      );

      // Tap NEXT to advance to S6
      expect(find.text('NEXT'), findsOneWidget);
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(tourController.currentStep, TourStep.s6Ranks);
    });

    testWidgets('S5 Coach mark target tap on EVENTS tab advances step to S6', (tester) async {
      await tourController.initForUser(
        userId: 'u-tour-events-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      expect(tourController.currentStep, TourStep.s5Events);

      await tester.pumpWidget(buildEventsTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // Tap the spotlight target over EVENTS tab
      final targetRect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.eventsTab);
      expect(targetRect, isNotNull);
      await tester.tapAt(targetRect!.center);
      await tester.pumpAndSettle();

      // Advanced to S6 Ranks
      expect(tourController.currentStep, TourStep.s6Ranks);
    });

    testWidgets('S5 Coach mark Skip button skips the entire tour', (tester) async {
      await tourController.initForUser(
        userId: 'u-tour-events-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      expect(tourController.currentStep, TourStep.s5Events);

      await tester.pumpWidget(buildEventsTestApp(controller: tourController));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.skipped);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('State-aware skipping: S5 is skipped if hasEventsTab is false', (tester) async {
      tourController.hasEventsTabGetter = () => false;

      await tourController.initForUser(
        userId: 'no_events_user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4

      expect(tourController.currentStep, TourStep.s4Community);

      // Advancing past S4 should silently skip S5 because hasEventsTab == false
      await tourController.nextStep();
      expect(tourController.currentStep, TourStep.s6Ranks);
      expect(tourController.completedSteps.contains(TourStep.s5Events), isTrue);
    });

    testWidgets('S5 Coach mark renders without overflow under 200% font scale on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'u-tour-events-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5

      final msgP = MessagesProvider(
        conversationStreamLoader: (_) => Stream.value(const []),
        unreadCountsLoader: (_, __) async => const {},
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                initialUser: testUser,
                listenToAuthChanges: false,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => PostsProvider(
                initialPosts: [samplePost],
                postsPageLoader: ({required limit, required offset}) async => [samplePost],
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => UsersProvider(
                initialUsers: [testUser],
                usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async => [testUser],
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => EngagementProvider(
                eligibleEventsLoader: () async => [sampleEvent],
              ),
            ),
            ChangeNotifierProvider<MessagesProvider>.value(value: msgP),
            ChangeNotifierProvider<TourController>.value(value: tourController),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: TourHost(
                  child: CommunityScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
    });
  });
}

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
    id: 'u-tour-user',
    name: 'Builder One',
    handle: 'builder1',
    email: 'builder1@example.com',
    avatar: '',
    color: Colors.black,
    aura: 50,
    roles: const ['Student'],
    year: '2nd Year',
    branch: 'CSE',
    building: 'Block A',
    stack: const ['Flutter'],
    followers: 5,
    following: 5,
    bio: '',
    college: 'IIIT',
    githubHandle: 'builder1',
    profileCompleted: true,
    currentStreak: 1,
  );

  final samplePost = PostModel(
    id: 'p-1',
    userId: 'other-user',
    content: 'Hello DevSpace builders!',
    tags: const ['flutter'],
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    likes: 2,
    comments: 1,
  );

  const sampleEvent = EventAccessModel(
    id: 'e-1',
    title: 'Hackathon 2026',
    description: 'Build projects and ship',
    requiredAura: 50,
    link: 'https://example.com',
    type: 'hackathon',
    unlocked: true,
    locked: false,
    date: 'Dec 2026',
    organizer: 'DevSpace',
    location: 'Online',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
    TourAnchorRegistry.instance.clear();
  });

  Widget buildCommunityTestApp({
    required TourController controller,
    List<PostModel>? posts,
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
            initialPosts: posts ?? [samplePost],
            postsPageLoader: ({required limit, required offset}) async =>
                posts ?? [samplePost],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: [testUser],
            usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async =>
                [testUser],
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

  group('Stage 4: Community Tab (S4)', () {
    testWidgets('S4 Coach mark renders spotlight on create post FAB and advances on NEXT tap', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tourController.initForUser(
        userId: 'u-tour-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      // Advance through S1, S2, S3 to S4
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      expect(tourController.currentStep, TourStep.s4Community);

      await tester.pumpWidget(buildCommunityTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // S4 Coach mark is visible
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s4CommunityTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s4CommunityBody), findsOneWidget);

      // Verify exactly one Glitch in coach mark
      expect(
        find.descendant(
          of: find.byType(CoachMarkOverlay),
          matching: find.byType(Glitch),
        ),
        findsOneWidget,
      );

      // Tap NEXT to advance to S5
      expect(find.text('NEXT'), findsOneWidget);
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tourController.currentStep, TourStep.s5Events);
    });

    testWidgets('S4 Coach mark target tap triggers ComposeBox sheet and advances step', (tester) async {
      await tourController.initForUser(
        userId: 'u-tour-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      expect(tourController.currentStep, TourStep.s4Community);

      await tester.pumpWidget(buildCommunityTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // Tap the spotlight target
      final targetRect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.createPostButton);
      expect(targetRect, isNotNull);
      await tester.tapAt(targetRect!.center);
      await tester.pumpAndSettle();

      // Advanced to S5 Events
      expect(tourController.currentStep, TourStep.s5Events);
    });

    testWidgets('S4 Coach mark Skip button skips the entire tour', (tester) async {
      await tourController.initForUser(
        userId: 'u-tour-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      expect(tourController.currentStep, TourStep.s4Community);

      await tester.pumpWidget(buildCommunityTestApp(controller: tourController));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tourController.status, TourStatus.skipped);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('State-aware skipping: S4 is skipped if user already has >= 1 post', (tester) async {
      tourController.postsCountGetter = () => 1;

      await tourController.initForUser(
        userId: 'active_poster_user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3

      expect(tourController.currentStep, TourStep.s3Play);

      // Advancing past S3 should silently skip S4 because posts count >= 1
      await tourController.nextStep();
      expect(tourController.currentStep, TourStep.s5Events);
      expect(tourController.completedSteps.contains(TourStep.s4Community), isTrue);
    });

    testWidgets('S4 Coach mark renders without overflow under 200% font scale on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tourController.initForUser(
        userId: 'u-tour-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4

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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
    });
  });
}

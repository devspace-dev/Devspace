import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/features/ranks/screens/ranks_screen.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/tour_copy.dart';
import 'package:devspace/features/tour/widgets/coach_mark_overlay.dart';
import 'package:devspace/features/tour/widgets/tour_host.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/users_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late TourController tourController;

  final testNewUser = UserModel(
    id: 'u-ranks-new',
    name: 'Newbie Builder',
    handle: 'newbie',
    email: 'newbie@example.com',
    avatar: '',
    color: Colors.black,
    aura: 0,
    roles: const ['Student'],
    year: '1st Year',
    branch: 'CSE',
    building: 'Block C',
    stack: const ['Flutter'],
    followers: 0,
    following: 0,
    bio: '',
    college: 'IIIT',
    githubHandle: 'newbie',
    profileCompleted: true,
    currentStreak: 0,
  );

  final testExistingUser = UserModel(
    id: 'u-ranks-existing',
    name: 'Pro Builder',
    handle: 'probuilder',
    email: 'pro@example.com',
    avatar: '',
    color: Colors.black,
    aura: 850,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'Block A',
    stack: const ['Flutter', 'Python'],
    followers: 12,
    following: 10,
    bio: 'Shipping daily',
    college: 'IIIT',
    githubHandle: 'probuilder',
    profileCompleted: true,
    currentStreak: 5,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
    TourAnchorRegistry.instance.clear();
  });

  Widget buildRanksTestApp({
    required TourController controller,
    required UserModel user,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: user,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: [user],
            usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async => [user],
          ),
        ),
        ChangeNotifierProvider<TourController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: TourHost(
            child: RanksScreen(),
          ),
        ),
      ),
    );
  }

  group('Stage 6: Ranks Tab (S6)', () {
    testWidgets('New user sees S6 Leaderboard coach mark with new user copy and finishes tour', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'u-ranks-new',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      // Advance through S1, S2, S3, S4, S5 to S6
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      await tourController.nextStep(); // S6
      expect(tourController.currentStep, TourStep.s6Ranks);

      await tester.pumpWidget(buildRanksTestApp(controller: tourController, user: testNewUser));
      await tester.pumpAndSettle();

      // S6 Coach mark is visible
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s6RanksTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s6RanksBodyNew), findsOneWidget);

      // Verify mascot is rendered
      expect(
        find.descendant(
          of: find.byType(CoachMarkOverlay),
          matching: find.byType(Glitch),
        ),
        findsOneWidget,
      );

      // Tap FINISH button to complete the tour
      expect(find.text('FINISH'), findsOneWidget);
      await tester.tap(find.text('FINISH'));
      await tester.pumpAndSettle();

      // Tour completed
      expect(tourController.status, TourStatus.completed);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('Existing user sees S6 Leaderboard coach mark with climb copy', (tester) async {
      await tourController.initForUser(
        userId: 'u-ranks-existing',
        isNewRegistration: false,
      );
      await tourController.checkAndStartTour();

      // Existing user flow: S1 -> S3b -> S4 -> S5 -> S6
      await tourController.nextStep(); // S3b
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      await tourController.nextStep(); // S6
      expect(tourController.currentStep, TourStep.s6Ranks);

      await tester.pumpWidget(buildRanksTestApp(controller: tourController, user: testExistingUser));
      await tester.pumpAndSettle();

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s6RanksTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s6RanksBodyClimb), findsOneWidget);

      // Tap FINISH button
      await tester.tap(find.text('FINISH'));
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.completed);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('Target tap on myRankRow completes tour', (tester) async {
      await tourController.initForUser(
        userId: 'u-ranks-new',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      await tourController.nextStep(); // S6
      expect(tourController.currentStep, TourStep.s6Ranks);

      await tester.pumpWidget(buildRanksTestApp(controller: tourController, user: testNewUser));
      await tester.pumpAndSettle();

      final targetRect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.myRankRow);
      expect(targetRect, isNotNull);
      await tester.tapAt(targetRect!.center);
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.completed);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('Skip button on S6 marks tour as skipped', (tester) async {
      await tourController.initForUser(
        userId: 'u-ranks-new',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      await tourController.nextStep(); // S6

      await tester.pumpWidget(buildRanksTestApp(controller: tourController, user: testNewUser));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.skipped);
      expect(tourController.currentStep, isNull);
    });

    testWidgets('S6 Coach mark renders without overflow under 200% font scale on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'u-ranks-new',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3
      await tourController.nextStep(); // S4
      await tourController.nextStep(); // S5
      await tourController.nextStep(); // S6

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider(
                initialUser: testNewUser,
                listenToAuthChanges: false,
              ),
            ),
            ChangeNotifierProvider(
              create: (_) => UsersProvider(
                initialUsers: [testNewUser],
                usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async => [testNewUser],
              ),
            ),
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
                  child: RanksScreen(),
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

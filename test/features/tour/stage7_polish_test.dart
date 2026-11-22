import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/services/reward_feedback.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/theme_provider.dart';
import 'package:devspace/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late TourController tourController;

  final testUser = UserModel(
    id: 'u-stage7-user',
    name: 'Settings Tester',
    handle: 'settingstester',
    email: 'tester@example.com',
    avatar: '',
    color: Colors.black,
    aura: 250,
    roles: const ['Student'],
    year: '2nd Year',
    branch: 'CSE',
    building: 'Block B',
    stack: const ['Flutter'],
    followers: 5,
    following: 5,
    bio: 'Testing polish',
    college: 'IIIT',
    githubHandle: 'settingstester',
    profileCompleted: true,
    currentStreak: 2,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
    TourAnchorRegistry.instance.clear();
  });

  Widget buildSettingsTestApp({
    required TourController controller,
    required UserModel user,
    double fontScale = 1.0,
    Size screenSize = const Size(360, 640),
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
          create: (_) => PostsProvider(
            initialPosts: const [],
            postsPageLoader: ({required limit, required offset}) async => const [],
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<TourController>.value(value: controller),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(fontScale),
          ),
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  group('Stage 7: Tour Polish & Edge Cases', () {
    testWidgets('SettingsScreen renders Haptic feedback toggle and updates preference', (tester) async {
      await RewardFeedback.setHapticsEnabled(true);
      expect(RewardFeedback.isHapticsEnabledSync, isTrue);

      await tester.pumpWidget(buildSettingsTestApp(
        controller: tourController,
        user: testUser,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Haptic feedback'), 150.0);
      expect(find.text('Haptic feedback'), findsOneWidget);

      // Toggle off
      await tester.tap(find.text('Haptic feedback'));
      await tester.pumpAndSettle();

      expect(RewardFeedback.isHapticsEnabledSync, isFalse);

      // Toggle back on
      await tester.tap(find.text('Haptic feedback'));
      await tester.pumpAndSettle();

      expect(RewardFeedback.isHapticsEnabledSync, isTrue);
    });

    testWidgets('SettingsScreen renders Replay tour button and resets tour to S1 Welcome', (tester) async {
      await tourController.initForUser(
        userId: 'u-stage7-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.completeTour();
      expect(tourController.status, TourStatus.completed);
      expect(tourController.currentStep, isNull);

      await tester.pumpWidget(buildSettingsTestApp(
        controller: tourController,
        user: testUser,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Replay tour'), 150.0);
      expect(find.text('Replay tour'), findsOneWidget);
      await tester.tap(find.text('Replay tour'));
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.inProgress);
      expect(tourController.currentStep, TourStep.s1Welcome);
    });

    testWidgets('TourController pauseTour and resumeTour update tour active state without crashing', (tester) async {
      await tourController.initForUser(
        userId: 'u-stage7-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      expect(tourController.isTourActive, isTrue);
      expect(tourController.isPaused, isFalse);

      tourController.pauseTour();
      expect(tourController.isPaused, isTrue);
      expect(tourController.isTourActive, isFalse);

      tourController.resumeTour();
      expect(tourController.isPaused, isFalse);
      expect(tourController.isTourActive, isTrue);
    });

    testWidgets('TourController routeNavigator auto-navigates on step transitions', (tester) async {
      final visitedRoutes = <String>[];
      tourController.routeNavigator = (route) {
        visitedRoutes.add(route);
      };

      await tourController.initForUser(
        userId: 'u-stage7-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour(); // S1

      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3 (Play) -> routes to /play
      expect(visitedRoutes, contains('/play'));

      await tourController.nextStep(); // S4 (Community) -> routes to /community
      expect(visitedRoutes, contains('/community'));

      await tourController.nextStep(); // S5 (Events) -> on community
      await tourController.nextStep(); // S6 (Ranks) -> routes to /ranks
      expect(visitedRoutes, contains('/ranks'));
    });

    testWidgets('Practice completion confirmed hook fires S7 reward modal', (tester) async {
      await tourController.initForUser(
        userId: 'u-stage7-user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3

      expect(tourController.currentStep, TourStep.s3Play);

      tourController.handlePracticeCompletionConfirmed();
      expect(tourController.currentStep, TourStep.s7RewardModal);
    });

    testWidgets('SettingsScreen renders without overflow under 200% font scale on 360dp width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsTestApp(
        controller: tourController,
        user: testUser,
        fontScale: 2.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Haptic feedback'), 150.0);
      expect(find.text('Haptic feedback'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Replay tour'), 150.0);
      expect(find.text('Replay tour'), findsOneWidget);
    });
  });
}

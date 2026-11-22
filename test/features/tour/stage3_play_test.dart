import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/features/play/screens/play_screen.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/tour_copy.dart';
import 'package:devspace/features/tour/widgets/coach_mark_overlay.dart';
import 'package:devspace/features/tour/widgets/tour_host.dart';
import 'package:devspace/features/tour/widgets/tour_popups.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TourController tourController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
    TourAnchorRegistry.instance.clear();
  });

  UserModel makeUser({
    required String id,
    required String name,
    required String handle,
    required int aura,
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: handle,
      email: '$handle@example.com',
      avatar: '',
      color: Colors.black,
      aura: aura,
      roles: const ['Student'],
      year: '2nd Year',
      branch: 'CSE',
      building: 'Block A',
      stack: const ['Flutter'],
      followers: 5,
      following: 5,
      bio: '',
      college: 'JNU',
      githubHandle: handle,
      profileCompleted: true,
      isFollowing: false,
    );
  }

  Widget buildPlayTestApp({
    required TourController controller,
    String userId = 'test_play_user',
  }) {
    final user = makeUser(
      id: userId,
      name: 'Player One',
      handle: 'playerone',
      aura: 50,
    );
    final auth = AuthProvider(initialUser: user, listenToAuthChanges: false);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<EngagementProvider>(create: (_) => EngagementProvider()),
        ChangeNotifierProvider<TourController>.value(value: controller),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: TourHost(
            child: PlayScreen(),
          ),
        ),
      ),
    );
  }

  group('Stage 3: Play Tab (S3, S3b, S7)', () {
    testWidgets('S3 Coach mark renders spotlight on Noob Practice card and advances on NEXT tap', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'test_play_user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      // Skip past S1 and S2 to S3
      await tourController.nextStep(); // to S2
      await tourController.nextStep(); // to S3
      expect(tourController.currentStep, TourStep.s3Play);

      await tester.pumpWidget(buildPlayTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // Verify Play screen loaded and S3 Coach mark spotlight is active
      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s3PlayTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s3PlayBody), findsOneWidget);

      // Tap NEXT on the coach mark
      expect(find.text('NEXT'), findsOneWidget);
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Advanced to S4 Community
      expect(tourController.currentStep, TourStep.s4Community);
    });

    testWidgets('S3b Existing user sees NEW ARENA RULES coach mark and advances cleanly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tourController.initForUser(
        userId: 'existing_play_user',
        isNewRegistration: false,
      );
      await tourController.checkAndStartTour();
      // For existing user, S1 advances directly to S3b
      await tourController.nextStep();
      expect(tourController.currentStep, TourStep.s3bPlayExisting);

      await tester.pumpWidget(buildPlayTestApp(controller: tourController));
      await tester.pumpAndSettle();

      expect(find.byType(CoachMarkOverlay), findsOneWidget);
      expect(find.text(TourCopy.s3bPlayTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s3bPlayBody), findsOneWidget);

      // Tap NEXT
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(tourController.currentStep, TourStep.s4Community);
    });

    testWidgets('State-aware skipping: S3 is skipped if user already has >= 1 practice solve', (tester) async {
      tourController.practiceCompletionsCountGetter = () => 1;

      await tourController.initForUser(
        userId: 'solved_user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      expect(tourController.currentStep, TourStep.s2Goal);

      // Advancing past S2 should silently skip S3 because practice count >= 1
      await tourController.nextStep();
      expect(tourController.currentStep, TourStep.s4Community);
      expect(tourController.completedSteps.contains(TourStep.s3Play), isTrue);
    });

    testWidgets('S7 Celebration modal triggers when practice completion is confirmed', (tester) async {
      await tourController.initForUser(
        userId: 'reward_user',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // S2
      await tourController.nextStep(); // S3

      expect(tourController.currentStep, TourStep.s3Play);

      // Simulate server confirming practice question completion
      tourController.handlePracticeCompletionConfirmed();
      expect(tourController.currentStep, TourStep.s7RewardModal);

      await tester.pumpWidget(buildPlayTestApp(controller: tourController));
      await tester.pumpAndSettle();

      // S7 Celebration modal with Glitch win animation is displayed
      expect(find.text(TourCopy.s7RewardTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s7RewardBody), findsOneWidget);
      expect(find.text(TourCopy.s7BadgeEarned), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TourModalPopup),
          matching: find.byType(Glitch),
        ),
        findsOneWidget,
      );

      // Tap KEEP GOING to advance to S4
      expect(find.text(TourCopy.s7KeepGoing.toUpperCase()), findsOneWidget);
      await tester.tap(find.text(TourCopy.s7KeepGoing.toUpperCase()));
      await tester.pumpAndSettle();

      expect(tourController.currentStep, TourStep.s4Community);
    });
  });
}

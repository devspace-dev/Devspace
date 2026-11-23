import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/core/widgets/ds_button.dart';
import 'package:devspace/core/widgets/glitch.dart';
import 'package:devspace/features/path/providers/path_provider.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';
import 'package:devspace/features/tour/tour_copy.dart';
import 'package:devspace/features/tour/widgets/tour_host.dart';
import 'package:devspace/features/tour/widgets/tour_popups.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TourController tourController;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tourController = TourController();
  });

  Widget buildTestApp({
    required Widget child,
    TourController? controller,
    PathProvider? pathProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TourController>.value(
          value: controller ?? tourController,
        ),
        if (pathProvider != null)
          ChangeNotifierProvider<PathProvider>.value(value: pathProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TourHost(child: child),
        ),
      ),
    );
  }

  group('Stage 2: Welcome and Goal (S1, S2)', () {
    testWidgets('S1 Welcome modal renders over shell and advances to S2 on CTA tap', (tester) async {
      await tourController.initForUser(
        userId: 'test_user_1',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      expect(tourController.currentStep, TourStep.s1Welcome);

      await tester.pumpWidget(
        buildTestApp(
          child: const Center(child: Text('Underlying App Content')),
        ),
      );
      await tester.pumpAndSettle();

      // Both underlying content and welcome modal are present in widget tree
      expect(find.text('Underlying App Content'), findsOneWidget);
      expect(find.text('WELCOME TO DEVSPACE'), findsOneWidget);
      expect(find.byType(Glitch), findsOneWidget);

      // Verify CTA button and tap it
      expect(find.text(TourCopy.s1WelcomeCta.toUpperCase()), findsOneWidget);
      await tester.tap(find.text(TourCopy.s1WelcomeCta.toUpperCase()));
      await tester.pumpAndSettle();

      // Advanced to S2 Goal
      expect(tourController.currentStep, TourStep.s2Goal);
      expect(find.text(TourCopy.s2GoalTitle.toUpperCase()), findsOneWidget);
    });

    testWidgets('S1 Welcome modal allows skipping entire tour cleanly', (tester) async {
      await tourController.initForUser(
        userId: 'test_user_2',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();

      await tester.pumpWidget(
        buildTestApp(
          child: const Center(child: Text('Underlying App Content')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(TourCopy.s1WelcomeSkip), findsOneWidget);
      await tester.tap(find.text(TourCopy.s1WelcomeSkip));
      await tester.pumpAndSettle();

      expect(tourController.status, TourStatus.skipped);
      expect(tourController.isTourActive, isFalse);
      // S1 modal is gone
      expect(find.text('WELCOME TO DEVSPACE'), findsNothing);
    });

    testWidgets('S2 Goal sheet configures path, shows Goal Locked celebration, and advances', (tester) async {
      await tourController.initForUser(
        userId: 'test_user_3',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tourController.nextStep(); // Advance to S2

      expect(tourController.currentStep, TourStep.s2Goal);

      var activatedRoadmap = '';
      final mockPathProvider = PathProvider(
        currentUserIdGetter: () => 'test_user_3',
        userRoadmapsLoader: (_) async => [],
        roadmapProgressLoader: (_, __) async => {},
        roadmapActivator: ({
          required userId,
          required roadmapId,
          required level,
          required weeklyHours,
          previousActiveRoadmapId,
        }) async {
          activatedRoadmap = roadmapId;
          return true;
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          pathProvider: mockPathProvider,
          child: const Center(child: Text('Underlying App Content')),
        ),
      );
      await tester.pumpAndSettle();

      // Verify S2 Goal sheet rendered with options and 6h default commitment
      expect(find.text(TourCopy.s2GoalTitle.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s2OptionDsaTitle), findsOneWidget);
      expect(find.text('6 hrs / wk'), findsOneWidget);
      expect(find.text('SWEET SPOT'), findsOneWidget);

      // Select Flutter roadmap option
      await tester.tap(find.text(TourCopy.s2OptionFlutterTitle));
      await tester.pump();

      // Tap Confirm: "SET UP MY PATH"
      expect(find.text(TourCopy.s2GoalAction.toUpperCase()), findsOneWidget);
      await tester.tap(find.text(TourCopy.s2GoalAction.toUpperCase()));
      await tester.pump();

      // Goal locked celebration state with Glitch win animation
      expect(find.text(TourCopy.s2GoalLocked.toUpperCase()), findsOneWidget);
      expect(find.text(TourCopy.s2GoalLockedBody), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // Tap CONTINUE to proceed to S3
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(activatedRoadmap, 'flutter');
      expect(tourController.currentStep, TourStep.s3Play);
    });

    testWidgets('State-aware skipping: S2 is silently skipped if user already has an active roadmap', (tester) async {
      tourController.hasActiveRoadmapGetter = () => true;

      await tourController.initForUser(
        userId: 'test_user_4',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      expect(tourController.currentStep, TourStep.s1Welcome);

      // Advancing past S1 should automatically skip S2 because active roadmap exists
      await tourController.nextStep();
      expect(tourController.currentStep, TourStep.s3Play);
      expect(tourController.completedSteps.contains(TourStep.s2Goal), isTrue);
    });

    testWidgets('First-run trigger: Backfill triggers for existing users with 0 completed nodes', (tester) async {
      await tourController.initForUser(
        userId: 'existing_user_no_progress',
        isNewRegistration: false,
      );

      expect(tourController.status, TourStatus.notStarted);

      // Trigger tour
      await tourController.checkAndStartTour();
      expect(tourController.status, TourStatus.inProgress);
      expect(tourController.currentStep, TourStep.s1Welcome);
    });

    testWidgets('Tour overlays have no yellow double underline (Material text decoration clean)', (tester) async {
      await tourController.initForUser(
        userId: 'test_user_decorations',
        isNewRegistration: true,
      );
      await tourController.checkAndStartTour();
      await tester.pumpWidget(
        buildTestApp(
          child: const Center(child: Text('Underlying App Content')),
        ),
      );
      await tester.pumpAndSettle();

      // Check all rendered text widgets in TourModalPopup
      for (final element in find.byType(Text).evaluate()) {
        final textWidget = element.widget as Text;
        expect(textWidget.style?.decoration, isNot(TextDecoration.underline));
      }

      // Advance to S2 Goal sheet
      await tourController.nextStep();
      await tester.pumpAndSettle();

      for (final element in find.byType(Text).evaluate()) {
        final textWidget = element.widget as Text;
        expect(textWidget.style?.decoration, isNot(TextDecoration.underline));
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devspace/features/tour/models/tour_step.dart';
import 'package:devspace/features/tour/services/tour_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TourController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = TourController.instance;
    controller.resetForTest();
  });

  group('TourController state machine tests', () {
    test('initializes new user and executes sequential progression', () async {
      await controller.initForUser(userId: 'u_new', isNewRegistration: true);
      expect(controller.status, TourStatus.notStarted);
      expect(controller.isNewUser, isTrue);

      // Start tour
      await controller.checkAndStartTour();
      expect(controller.status, TourStatus.inProgress);
      expect(controller.currentStep, TourStep.s1Welcome);

      // S1 -> S2 (Goal)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s2Goal);

      // S2 -> S3 (Play)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s3Play);

      // S3 -> S4 (Community)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s4Community);

      // S4 -> S5 (Events)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s5Events);

      // S5 -> S6 (Ranks)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s6Ranks);

      // S6 -> Completion
      await controller.nextStep();
      expect(controller.status, TourStatus.completed);
      expect(controller.currentStep, isNull);
    });

    test('initializes existing user with shorter upgrade tour', () async {
      await controller.initForUser(userId: 'u_existing', isNewRegistration: false);
      expect(controller.isNewUser, isFalse);

      await controller.checkAndStartTour();
      expect(controller.currentStep, TourStep.s1Welcome);

      // Existing user S1 advances to S3b (Play existing) skipping S2
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s3bPlayExisting);

      // S3b -> S4 (Community)
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s4Community);
    });

    test('state-aware skipping: skips S2 if active roadmap already exists', () async {
      controller.hasActiveRoadmapGetter = () => true;

      await controller.initForUser(userId: 'u_has_path', isNewRegistration: true);
      await controller.checkAndStartTour();
      expect(controller.currentStep, TourStep.s1Welcome);

      // Advances past S1 -> S2 is silently skipped because roadmap exists -> lands on S3
      await controller.nextStep();
      expect(controller.currentStep, TourStep.s3Play);
      expect(controller.completedSteps, contains(TourStep.s2Goal));
    });

    test('state-aware skipping: skips S3 if practice completions >= 1', () async {
      controller.practiceCompletionsCountGetter = () => 3;

      await controller.initForUser(userId: 'u_has_practice', isNewRegistration: true);
      await controller.checkAndStartTour();

      await controller.nextStep(); // S2
      await controller.nextStep(); // S3 is skipped -> lands on S4
      expect(controller.currentStep, TourStep.s4Community);
      expect(controller.completedSteps, contains(TourStep.s3Play));
    });

    test('pause and resume manages active state correctly', () async {
      await controller.initForUser(userId: 'u_pause', isNewRegistration: true);
      await controller.checkAndStartTour();

      expect(controller.isTourActive, isTrue);
      expect(controller.isPaused, isFalse);

      controller.pauseTour();
      expect(controller.isPaused, isTrue);
      expect(controller.isTourActive, isFalse);

      controller.resumeTour();
      expect(controller.isPaused, isFalse);
      expect(controller.isTourActive, isTrue);
    });

    test('skipTour persists skipped state and stops progression', () async {
      await controller.initForUser(userId: 'u_skip', isNewRegistration: true);
      await controller.checkAndStartTour();

      await controller.skipTour();
      expect(controller.status, TourStatus.skipped);
      expect(controller.currentStep, isNull);

      // Check re-init reads skipped from prefs
      final newController = TourController();
      await newController.initForUser(userId: 'u_skip', isNewRegistration: false);
      expect(newController.status, TourStatus.skipped);
    });

    test('replayTour restarts from S1 and clears completed steps', () async {
      await controller.initForUser(userId: 'u_replay', isNewRegistration: true);
      await controller.checkAndStartTour();
      await controller.nextStep();
      await controller.completeTour();
      expect(controller.status, TourStatus.completed);

      await controller.replayTour();
      expect(controller.status, TourStatus.inProgress);
      expect(controller.currentStep, TourStep.s1Welcome);
      expect(controller.completedSteps, isEmpty);
    });
  });
}

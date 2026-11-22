import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/reward_feedback.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/glitch.dart';
import '../../path/models/roadmap_model.dart';
import '../../path/providers/path_provider.dart';
import '../models/tour_step.dart';
import '../services/tour_controller.dart';
import '../tour_copy.dart';
import 'tour_popups.dart';

/// Root overlay host that renders the active tour step over the main application shell.
/// Ensures exactly one tour popup/sheet is visible at any time.
class TourHost extends StatelessWidget {
  final Widget child;

  const TourHost({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tour = context.watch<TourController>();

    if (!tour.isTourActive) {
      return child;
    }

    Widget? overlayWidget;

    switch (tour.currentStep) {
      case TourStep.s1Welcome:
        overlayWidget = Center(
          child: TourModalPopup(
            title: TourCopy.s1WelcomeTitle,
            body: TourCopy.s1WelcomeBody,
            mood: GlitchMood.hype,
            primaryButtonLabel: TourCopy.s1WelcomeCta,
            onPrimaryPressed: () {
              RewardFeedback.play(RewardFeedbackKind.subtle);
              tour.nextStep();
            },
            secondaryButtonLabel: TourCopy.s1WelcomeSkip,
            onSecondaryPressed: () => tour.skipTour(),
          ),
        );
        break;

      case TourStep.s2Goal:
        overlayWidget = Align(
          alignment: Alignment.bottomCenter,
          child: TourGoalSheet(
            onGoalSelected: (roadmapId) async {
              try {
                final path = context.read<PathProvider>();
                await path.selectRoadmap(
                  roadmapId: roadmapId,
                  level: RoadmapLevel.beginner,
                  weeklyHours: 6,
                );
              } catch (e) {
                debugPrint('TourHost activate roadmap error: $e');
              }
              await tour.selectGoal(roadmapId);
            },
            onSkip: () => tour.skipTour(),
          ),
        );
        break;

      default:
        overlayWidget = null;
        break;
    }

    if (overlayWidget == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Dark semi-transparent scrim
        ModalBarrier(
          color: Ds.ink.withValues(alpha: 0.8),
          dismissible: false,
        ),
        SafeArea(
          child: overlayWidget,
        ),
      ],
    );
  }
}

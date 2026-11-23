import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/reward_feedback.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/glitch.dart';
import '../../../widgets/compose_box.dart';
import '../../path/models/roadmap_model.dart';
import '../../path/providers/path_provider.dart';
import '../models/tour_step.dart';
import '../services/tour_controller.dart';
import '../tour_copy.dart';
import 'coach_mark_overlay.dart';
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
    TourController? maybeTour;
    try {
      maybeTour = context.watch<TourController>();
    } catch (_) {
      maybeTour = null;
    }

    if (maybeTour == null || !maybeTour.isTourActive) {
      return child;
    }

    final TourController tour = maybeTour;

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

      case TourStep.s3Play:
        final rect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.firstTierTile);
        overlayWidget = CoachMarkOverlay(
          targetRect: rect,
          title: TourCopy.s3PlayTitle,
          body: TourCopy.s3PlayBody,
          stepPill: tour.isNewUser ? 'STEP 3 OF 6' : 'STEP 2 OF 5',
          mood: GlitchMood.idle,
          primaryButtonLabel: 'NEXT',
          onPrimaryPressed: () => tour.nextStep(),
          secondaryButtonLabel: 'Skip',
          onSecondaryPressed: () => tour.skipTour(),
          onDismiss: () => tour.nextStep(),
          onTargetTap: () {
            context.push('/quiz/noob');
            tour.nextStep();
          },
        );
        break;

      case TourStep.s3bPlayExisting:
        final rect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.firstTierTile);
        overlayWidget = CoachMarkOverlay(
          targetRect: rect,
          title: TourCopy.s3bPlayTitle,
          body: TourCopy.s3bPlayBody,
          stepPill: 'STEP 2 OF 5',
          mood: GlitchMood.idle,
          primaryButtonLabel: 'NEXT',
          onPrimaryPressed: () => tour.nextStep(),
          secondaryButtonLabel: 'Skip',
          onSecondaryPressed: () => tour.skipTour(),
          onDismiss: () => tour.nextStep(),
          onTargetTap: () {
            context.push('/quiz/noob');
            tour.nextStep();
          },
        );
        break;

      case TourStep.s4Community:
        final rect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.createPostButton);
        overlayWidget = CoachMarkOverlay(
          targetRect: rect,
          title: TourCopy.s4CommunityTitle,
          body: TourCopy.s4CommunityBody,
          stepPill: tour.isNewUser ? 'STEP 4 OF 6' : 'STEP 3 OF 5',
          mood: GlitchMood.idle,
          primaryButtonLabel: 'NEXT',
          onPrimaryPressed: () => tour.nextStep(),
          secondaryButtonLabel: 'Skip',
          onSecondaryPressed: () => tour.skipTour(),
          onDismiss: () => tour.nextStep(),
          onTargetTap: () {
            ComposeBox.showCreatePostSheet(context);
            tour.nextStep();
          },
        );
        break;

      case TourStep.s5Events:
        final rect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.eventsTab);
        overlayWidget = CoachMarkOverlay(
          targetRect: rect,
          title: TourCopy.s5EventsTitle,
          body: TourCopy.s5EventsBody,
          stepPill: tour.isNewUser ? 'STEP 5 OF 6' : 'STEP 4 OF 5',
          mood: GlitchMood.idle,
          primaryButtonLabel: 'NEXT',
          onPrimaryPressed: () => tour.nextStep(),
          secondaryButtonLabel: 'Skip',
          onSecondaryPressed: () => tour.skipTour(),
          onDismiss: () => tour.nextStep(),
          onTargetTap: () {
            tour.nextStep();
          },
        );
        break;

      case TourStep.s6Ranks:
        final rect = TourAnchorRegistry.instance.getGlobalRect(TourAnchorId.myRankRow);
        final bodyText = tour.isNewUser
            ? TourCopy.s6RanksBodyNew
            : TourCopy.s6RanksBodyClimb;
        overlayWidget = CoachMarkOverlay(
          targetRect: rect,
          title: TourCopy.s6RanksTitle,
          body: bodyText,
          stepPill: tour.isNewUser ? 'STEP 6 OF 6' : 'STEP 5 OF 5',
          mood: GlitchMood.idle,
          primaryButtonLabel: 'FINISH',
          onPrimaryPressed: () => tour.completeTour(),
          secondaryButtonLabel: 'Skip',
          onSecondaryPressed: () => tour.skipTour(),
          onDismiss: () => tour.completeTour(),
          onTargetTap: () {
            tour.completeTour();
          },
        );
        break;

      case TourStep.s7RewardModal:
        overlayWidget = Center(
          child: TourModalPopup(
            title: TourCopy.s7RewardTitle,
            body: TourCopy.s7RewardBody,
            mood: GlitchMood.win,
            primaryButtonLabel: TourCopy.s7KeepGoing,
            onPrimaryPressed: () => tour.nextStep(),
            secondaryButtonLabel: TourCopy.s7SeeRank,
            onSecondaryPressed: () {
              tour.nextStep();
              context.go('/ranks');
            },
            extraContent: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Ds.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Ds.aura, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    TourCopy.s7BadgeEarned,
                    style: DsText.caption.copyWith(color: Ds.aura),
                  ),
                ],
              ),
            ),
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

    final isCoachMark = tour.currentStep == TourStep.s3Play ||
        tour.currentStep == TourStep.s3bPlayExisting ||
        tour.currentStep == TourStep.s4Community ||
        tour.currentStep == TourStep.s5Events ||
        tour.currentStep == TourStep.s6Ranks;

    return Stack(
      children: [
        child,
        if (!isCoachMark) ...[
          ModalBarrier(
            color: Ds.ink.withValues(alpha: 0.8),
            dismissible: false,
          ),
          SafeArea(
            child: overlayWidget,
          ),
        ] else ...[
          overlayWidget,
        ],
      ],
    );
  }
}

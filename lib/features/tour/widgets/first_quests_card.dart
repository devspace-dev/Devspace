import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/reward_feedback.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/glitch.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/posts_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../path/providers/path_provider.dart';
import '../models/tour_step.dart';
import '../services/tour_controller.dart';

class QuestItemData {
  final String id;
  final String title;
  final String? reward;
  final bool isCompleted;
  final VoidCallback onTap;

  const QuestItemData({
    required this.id,
    required this.title,
    this.reward,
    required this.isCompleted,
    required this.onTap,
  });
}

/// S8: First Quests card displayed on the Play tab until all starter quests are completed.
/// Progress is derived purely from real provider data with zero additional award flows.
class FirstQuestsCard extends StatelessWidget {
  final bool? overridePathDone;
  final bool? overrideSolveDone;
  final bool? overridePostDone;
  final bool? overrideEventDone;
  final bool? overrideBadgeDone;
  final bool showBadgeQuest;

  const FirstQuestsCard({
    super.key,
    this.overridePathDone,
    this.overrideSolveDone,
    this.overridePostDone,
    this.overrideEventDone,
    this.overrideBadgeDone,
    this.showBadgeQuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider?>()?.currentUserOrNull;
    final userId = user?.id ?? '';

    // 1. Pick your path (active roadmap)
    final pathDone = overridePathDone ??
        (context.watch<PathProvider?>()?.hasActiveRoadmap ?? false);

    // 2. Solve first question (practice completion >= 1)
    final solveDone = overrideSolveDone ??
        ((context.watch<PracticeProvider?>()?.totalCompletedCount ?? 0) >= 1);

    // 3. Make your first post (posts count >= 1)
    final postDone = overridePostDone ??
        (context.watch<PostsProvider?>()?.postsForUser(userId).isNotEmpty ?? false);

    // 4. Find an event (events tab visited or tour step completed)
    final tour = context.watch<TourController?>();
    final eventDone = overrideEventDone ??
        (tour?.completedSteps.contains(TourStep.s5Events) ?? false);

    // 5. Earn first badge (only shown if badge feature is active)
    final badgeDone = overrideBadgeDone ?? false;

    final quests = <QuestItemData>[
      QuestItemData(
        id: 'path',
        title: 'Pick your path',
        isCompleted: pathDone,
        onTap: () {
          try {
            GoRouter.maybeOf(context)?.go('/path');
          } catch (_) {}
        },
      ),
      QuestItemData(
        id: 'solve',
        title: 'Solve your first question',
        reward: '+5 AURA',
        isCompleted: solveDone,
        onTap: () {
          try {
            GoRouter.maybeOf(context)?.push('/quiz/noob');
          } catch (_) {}
        },
      ),
      QuestItemData(
        id: 'post',
        title: 'Make your first post',
        isCompleted: postDone,
        onTap: () {
          try {
            GoRouter.maybeOf(context)?.go('/community');
          } catch (_) {}
        },
      ),
      QuestItemData(
        id: 'event',
        title: 'Find an event',
        isCompleted: eventDone,
        onTap: () {
          try {
            GoRouter.maybeOf(context)?.go('/community');
          } catch (_) {}
        },
      ),
      if (showBadgeQuest || overrideBadgeDone != null)
        QuestItemData(
          id: 'badge',
          title: 'Earn your first badge',
          isCompleted: badgeDone,
          onTap: () {
            try {
              GoRouter.maybeOf(context)?.go('/profile');
            } catch (_) {}
          },
        ),
    ];

    final completedCount = quests.where((q) => q.isCompleted).length;
    final totalCount = quests.length;

    // Disappears completely when all remaining quests are done
    if (completedCount >= totalCount) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DsCard(
      padding: const EdgeInsets.all(16),
      borderColor: Ds.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Glitch mascot + Title + Progress count
          Row(
            children: [
              const Glitch(size: 26, mood: GlitchMood.hype),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'FIRST QUESTS',
                  style: DsText.label.copyWith(
                    color: Ds.aura,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Ds.navBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Ds.border),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: DsText.number.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Complete starter quests to kick off your builder routine.',
            style: DsText.caption,
          ),
          const SizedBox(height: 14),

          // Quest checklist
          ...quests.map((q) => _buildQuestTile(context, q)),
        ],
      ),
    ));
  }

  Widget _buildQuestTile(BuildContext context, QuestItemData quest) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: quest.isCompleted
            ? null
            : () {
                RewardFeedback.selection();
                quest.onTap();
              },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                quest.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: quest.isCompleted ? Ds.aura : Ds.muted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quest.title,
                  style: DsText.bodySm.copyWith(
                    color: quest.isCompleted ? Ds.muted : Ds.bone,
                    decoration: quest.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Ds.muted,
                  ),
                ),
              ),
              if (quest.reward != null && !quest.isCompleted) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Ds.aura.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quest.reward!,
                    style: DsText.caption.copyWith(
                      color: Ds.aura,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              if (!quest.isCompleted) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Ds.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/engagement_provider.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/opportunities_screen.dart';
import '../theme/app_colors.dart';

class EngagementOverview extends StatelessWidget {
  const EngagementOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EngagementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading &&
            provider.auraSummary == null &&
            provider.dailyChallenge == null &&
            provider.events.isEmpty) {
          return const SizedBox.shrink();
        }

        if (provider.error != null &&
            provider.auraSummary == null &&
            provider.dailyChallenge == null &&
            provider.events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Engagement data unavailable',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textFor(context),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.fetchOverview,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text3For(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = provider.auraSummary;
        final challenge = provider.dailyChallenge;
        final unlockedCount = provider.unlockedEvents.length;
        final lockedCount = provider.lockedEvents.length;

        return Column(
          children: [
            if (summary != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Aura',
                          value: '${summary.auraPoints}',
                          hint: summary.level,
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Current Streak',
                          value: '${summary.currentStreak}',
                          hint: 'Longest ${summary.longestStreak}',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Unlocked',
                          value: '$unlockedCount',
                          hint: '$lockedCount locked',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (challenge != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Daily Challenge',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textFor(context),
                              ),
                            ),
                          ),
                          Text(
                            challenge.completed
                                ? 'Completed'
                                : '+${challenge.pointsReward} aura',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: challenge.completed
                                  ? Colors.green
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.text2For(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${challenge.techStack} - ${challenge.difficulty}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text3For(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DailyChallengeScreen(),
                                ),
                              );
                            },
                            child: const Text('Open'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: challenge.completed ||
                                    provider.isSubmittingChallenge
                                ? null
                                : () => _showSubmissionSheet(context),
                            child: Text(
                              challenge.completed
                                  ? 'Submitted'
                                  : provider.isSubmittingChallenge
                                      ? 'Submitting...'
                                      : 'Submit Solution',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (provider.events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Opportunities',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textFor(context),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OpportunitiesScreen(),
                                ),
                              );
                            },
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...provider.events.take(4).map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    event.unlocked
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 18,
                                    color: event.unlocked
                                        ? Colors.green
                                        : AppColors.text3For(context),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textFor(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          event.unlocked
                                              ? '${event.type} - eligible now'
                                              : '${event.type} - needs ${event.requiredAura} aura',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.text3For(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showSubmissionSheet(BuildContext context) async {
    final textController = TextEditingController();
    final linkController = TextEditingController();

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Consumer<EngagementProvider>(
            builder: (context, provider, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit challenge solution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'What did you build or solve?',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: 'Optional link',
                    ),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      provider.error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.flame,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isSubmittingChallenge
                          ? null
                          : () async {
                              final ok = await context
                                  .read<EngagementProvider>()
                                  .submitDailyChallenge(
                                    submissionText: textController.text,
                                    submissionLink: linkController.text,
                                  );
                              if (context.mounted && ok) {
                                Navigator.of(sheetContext).pop(true);
                              }
                            },
                      child: Text(
                        provider.isSubmittingChallenge
                            ? 'Submitting...'
                            : 'Complete Challenge',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    textController.dispose();
    linkController.dispose();

    if (success == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge submitted. Aura updated.')),
      );
    }
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _Metric({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text3For(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text3For(context),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: child,
    );
  }
}

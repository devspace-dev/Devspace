import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<EngagementProvider>();
    final success = await provider.submitDailyChallenge(
      submissionText: _textController.text,
      submissionLink: _linkController.text,
    );

    if (!mounted) return;
    if (success) {
      _textController.clear();
      _linkController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge submitted. Aura updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: const Text('Daily Challenge'),
      ),
      body: Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          final challenge = provider.dailyChallenge;
          if (provider.isLoading && challenge == null) {
            return const AppLoadingState(
              title: 'Loading challenge',
              message: 'Pulling your daily task from the backend.',
            );
          }

          if (provider.error != null && challenge == null) {
            return AppErrorState(
              title: 'Could not load challenge',
              message: provider.error!,
              actionLabel: 'Retry',
              onAction: provider.fetchOverview,
            );
          }

          if (challenge == null) {
            return const AppEmptyState(
              icon: Icons.task_alt_outlined,
              title: 'No challenge assigned',
              message: 'Try again in a bit.',
            );
          }

          final completed = challenge.completed;

          return RefreshIndicator.adaptive(
            onRefresh: provider.fetchOverview,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          completed ? 'Completed' : 'Open',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: completed ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        '+${challenge.pointsReward} aura',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text2For(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 14,
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Submission',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3For(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  minLines: 4,
                  maxLines: 6,
                  enabled: !completed && !provider.isSubmittingChallenge,
                  decoration: const InputDecoration(
                    labelText: 'What did you build or solve?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  enabled: !completed && !provider.isSubmittingChallenge,
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: completed || provider.isSubmittingChallenge
                        ? null
                        : _submit,
                    child: Text(
                      completed
                          ? 'Already submitted'
                          : provider.isSubmittingChallenge
                              ? 'Submitting...'
                              : 'Submit challenge',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

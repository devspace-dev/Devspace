import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/daily_challenge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/app_ui_kit.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  String? _selectedOption;

  Future<void> _submit(EngagementProvider provider) async {
    final answer = (_selectedOption ?? '').trim();
    if (answer.isEmpty) return;

    final success = await provider.submitDailyChallenge(
      submissionText: answer,
      submissionLink: '',
    );

    if (!mounted) return;

    if (success) {
      final challenge = provider.dailyChallenge;
      final solved = challenge?.wasSolved ?? false;
      final awardedPoints =
          solved ? (challenge?.pointsReward ?? 20) : DailyChallengeModel.attemptReward;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            solved
                ? 'Correct answer. +$awardedPoints Aura added.'
                : 'Wrong answer. +$awardedPoints Aura for attempting. Mission locked until tomorrow.',
          ),
          backgroundColor: solved ? Colors.green : Colors.orange,
        ),
      );
      return;
    }

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: AppGradientBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Consumer<EngagementProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.dailyChallenge == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  final daily = provider.dailyChallenge;
                  if (daily == null) {
                    return const AppEmptyState(
                      icon: Icons.auto_awesome_rounded,
                      title: 'No mission today',
                      message: 'Check back later for a new mission.',
                    );
                  }

                  if (!daily.completed &&
                      _selectedOption != null &&
                      !daily.options.contains(_selectedOption)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedOption = null;
                        });
                      }
                    });
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMissionHeader(context, me),
                        const SizedBox(height: 24),
                        _buildMainCard(context, daily),
                        const SizedBox(height: 24),
                        if (!daily.completed) _buildActionSection(context, provider),
                        if (daily.completed) _buildCompletionStatus(context, daily),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'Daily Mission',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.textFor(context),
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildMissionHeader(BuildContext context, dynamic me) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _HeaderBadge(
          label: '${me?.currentStreak ?? 0} Day Streak',
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(width: 12),
        const _HeaderBadge(
          label: '+20 solve / +5 try',
          icon: Icons.bolt_rounded,
          color: AppColors.primary,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildMainCard(BuildContext context, DailyChallengeModel challenge) {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                label: challenge.difficulty.toUpperCase(),
                color: _getDifficultyColor(challenge.difficulty),
              ),
              AppBadge(
                label: challenge.techStack,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 18),
          _InfoBlock(
            title: 'Question',
            child: Text(
              challenge.question,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.text2For(context),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoBlock(
            title: 'Rule',
            child: Text(
              'You get one answer per day. Correct answers give +${challenge.pointsReward} aura. Wrong answers still give +${DailyChallengeModel.attemptReward} aura, but the mission locks until tomorrow.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.text2For(context),
              ),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActionSection(BuildContext context, EngagementProvider provider) {
    final challenge = provider.dailyChallenge;
    if (challenge == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose one answer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: challenge.options
              .map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: _selectedOption == option,
                  labelStyle: TextStyle(
                    color: _selectedOption == option
                        ? Colors.white
                        : AppColors.textFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: AppColors.bg2For(context),
                  selectedColor: AppColors.primary,
                  side: BorderSide(
                    color: _selectedOption == option
                        ? AppColors.primary
                        : AppColors.borderFor(context),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedOption = option;
                    });
                  },
                ),
              )
              .toList(),
        ).animate().fadeIn(delay: 420.ms),
        if (provider.error != null) ...[
          const SizedBox(height: 14),
          Text(
            provider.error!,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppButton(
          onPressed: _selectedOption == null ? null : () => _submit(provider),
          isLoading: provider.isSubmittingChallenge,
          child: const Text(
            'Lock Answer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ).animate().fadeIn(delay: 560.ms).moveY(begin: 20),
      ],
    );
  }

  Widget _buildCompletionStatus(
    BuildContext context,
    DailyChallengeModel challenge,
  ) {
    final solved = challenge.wasSolved;
    final points =
        solved ? challenge.pointsReward : DailyChallengeModel.attemptReward;
    final accent = solved ? Colors.green : Colors.orange;

    return AppCard(
      color: accent.withValues(alpha: 0.1),
      border: Border.all(color: accent.withValues(alpha: 0.2)),
      child: Row(
        children: [
          Icon(
            solved ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
            color: accent,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solved ? 'Mission solved' : 'Mission attempted',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  solved
                      ? 'You earned +$points Aura points. Your streak stays active.'
                      : 'You earned +$points Aura for trying. This mission is locked until tomorrow.',
                  style: TextStyle(
                    fontSize: 14,
                    color: accent.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2.seconds).fadeIn();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppColors.text3;
    }
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeaderBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoBlock({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

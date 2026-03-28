import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/daily_challenge_model.dart';
import '../providers/engagement_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/app_ui_kit.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  final TextEditingController _submissionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void dispose() {
    _submissionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit(EngagementProvider provider) async {
    final text = _submissionController.text.trim();
    final link = _linkController.text.trim();

    if (text.isEmpty && link.isEmpty) return;

    final challenge = provider.dailyChallenge;
    final success = await provider.submitDailyChallenge(
      submissionText: text,
      submissionLink: link,
    );

    if (mounted && success) {
      _submissionController.clear();
      _linkController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mission completed! +${challenge?.pointsReward ?? 0} Aura',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.error != null) {
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
                      message: 'Check back later for a new mission!',
                    );
                  }

                  final isCompleted = daily.completed;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMissionHeader(context, me),
                        const SizedBox(height: 24),
                        _buildMainCard(context, daily),
                        const SizedBox(height: 24),
                        if (!isCompleted) _buildActionSection(context, provider),
                        if (isCompleted) _buildCompletionStatus(context),
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
    return Row(
      children: [
        _HeaderBadge(
          label: '${me?.currentStreak ?? 0} Day Streak',
          icon: '🔥',
          color: Colors.orange,
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(width: 12),
        const _HeaderBadge(
          label: '+20 Aura',
          icon: '⚡',
          color: AppColors.primary,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
      ],
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    DailyChallengeModel challenge,
  ) {
    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(
                label: challenge.difficulty.toUpperCase(),
                color: _getDifficultyColor(challenge.difficulty),
              ),
              const SizedBox(width: 8),
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
          _sectionTitleFor(challenge),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _submissionController,
          hint: _answerHintFor(challenge),
          maxLines: challenge.isOneWordMission ? 1 : 4,
        ).animate().fadeIn(delay: 400.ms),
        if (challenge.isCodingMission) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _linkController,
            hint: 'GitHub / Demo Link (Optional)',
            maxLines: 1,
            prefixIcon: Icons.link_rounded,
          ).animate().fadeIn(delay: 500.ms),
        ],
        if (challenge.isMcqMission && challenge.options.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: challenge.options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: _submissionController.text.trim() == option,
                    onSelected: (_) {
                      setState(() {
                        _submissionController.text = option;
                      });
                    },
                  ),
                )
                .toList(),
          ).animate().fadeIn(delay: 450.ms),
        ],
        const SizedBox(height: 24),
        AppButton(
          onPressed: () => _submit(provider),
          isLoading: provider.isSubmittingChallenge,
          child: Text(
            _buttonLabelFor(challenge),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ).animate().fadeIn(delay: 600.ms).moveY(begin: 20),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textFor(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.text3For(context)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.text3For(context), size: 20) : null,
        fillColor: AppColors.bg2For(context),
        filled: true,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.borderFor(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.borderFor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCompletionStatus(BuildContext context) {
    final points =
        context.read<EngagementProvider>().dailyChallenge?.pointsReward ?? 0;
    return AppCard(
      color: Colors.green.withValues(alpha: 0.1),
      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mission Accomplished',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'You earned +$points Aura points today!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.withValues(alpha: 0.8),
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
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return AppColors.text3;
    }
  }

  String _sectionTitleFor(DailyChallengeModel challenge) {
    if (challenge.isCodingMission) return 'Your Submission';
    if (challenge.isMcqMission) return 'Your Answer';
    return 'Your Response';
  }

  String _answerHintFor(DailyChallengeModel challenge) {
    if (challenge.isCodingMission) {
      return 'Share what you built or learned...';
    }
    if (challenge.isMcqMission) {
      return 'Select or type the correct option';
    }
    return 'Enter the correct one-word answer';
  }

  String _buttonLabelFor(DailyChallengeModel challenge) {
    if (challenge.isCodingMission) return 'Submit Mission';
    if (challenge.isMcqMission) return 'Check Answer';
    return 'Submit Answer';
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final String icon;
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
          Text(icon, style: const TextStyle(fontSize: 16)),
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

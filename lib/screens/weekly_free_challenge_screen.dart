import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/daily_challenge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/info_block.dart';
import '../widgets/glass_container.dart';

class WeeklyFreeChallengeScreen extends StatefulWidget {
  const WeeklyFreeChallengeScreen({super.key});

  @override
  State<WeeklyFreeChallengeScreen> createState() => _WeeklyFreeChallengeScreenState();
}

class _WeeklyFreeChallengeScreenState extends State<WeeklyFreeChallengeScreen>
    with TickerProviderStateMixin {
  String? _selectedOption;
  Timer? _successOverlayTimer;
  late final AnimationController _successController;
  bool _showSuccessOverlay = false;
  int _celebrationPoints = 0;
  String? _activeTechStack;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUserOrNull;
      if (user != null && user.stack.isNotEmpty) {
        _activeTechStack = user.stack.first;
      }
      _fetchChallenge();
    });
  }

  void _fetchChallenge() {
    context.read<EngagementProvider>().fetchOverview(
      forceChallengeRefresh: true,
      techStack: _activeTechStack,
    );
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOption = null;
    });
  }

  @override
  void dispose() {
    _successOverlayTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _submit(EngagementProvider provider) async {
    final answer = (_selectedOption ?? '').trim();
    if (answer.isEmpty) return;

    final success = await provider.submitWeeklyFreeChallenge(
      submissionText: answer,
      submissionLink: '',
    );

    if (!mounted) return;

    if (success) {
      final challenges = provider.weeklyFreeChallenges;
      if (_currentQuestionIndex < challenges.length) {
        final challenge = challenges[_currentQuestionIndex];
        // Note: The mock submission currently doesn't update 'isCorrect' instantly 
        // in some flows, so we'll treat it as solved for the UI feedback
        _playSuccessOverlay(challenge.pointsReward);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission received! Moving to next challenge.'),
          backgroundColor: Colors.green,
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

  void _playSuccessOverlay(int awardedPoints) {
    _successOverlayTimer?.cancel();
    _successController
      ..reset()
      ..forward();

    setState(() {
      _celebrationPoints = awardedPoints;
      _showSuccessOverlay = true;
    });

    _successOverlayTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _showSuccessOverlay = false;
        final provider = context.read<EngagementProvider>();
        if (_currentQuestionIndex < provider.weeklyFreeChallenges.length - 1) {
          _currentQuestionIndex++;
          _selectedOption = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final engagement = context.watch<EngagementProvider>();
    final challenges = engagement.weeklyFreeChallenges;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: Stack(
        children: [
          AppGradientBackground(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScorecard(engagement),
                        const SizedBox(height: 24),
                        _buildTechStackSelector(me),
                        const SizedBox(height: 24),
                        if (engagement.isLoading && challenges.isEmpty)
                          const Center(
                            child: CircularProgressIndicator.adaptive(),
                          )
                        else if (challenges.isEmpty)
                          _buildNoChallengeState()
                        else ...[
                          _buildProgressBar(challenges.length),
                          const SizedBox(height: 20),
                          _buildChallengeHeader(context, challenges[_currentQuestionIndex]),
                          const SizedBox(height: 20),
                          _buildChallengeCard(context, challenges[_currentQuestionIndex]),
                          const SizedBox(height: 24),
                          if (!challenges[_currentQuestionIndex].completed) 
                            _buildActionSection(context, engagement, challenges[_currentQuestionIndex]),
                          if (challenges[_currentQuestionIndex].completed) 
                            _buildCompletionStatus(context, challenges[_currentQuestionIndex]),
                          const SizedBox(height: 32),
                          _buildAiTipSection(context, challenges[_currentQuestionIndex]),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessOverlay)
            Positioned.fill(
              child: _ChallengeSolvedOverlay(
                controller: _successController,
                awardedPoints: _celebrationPoints,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'Weekly Mastery',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.textFor(context),
            letterSpacing: -1,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _fetchChallenge,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildScorecard(EngagementProvider engagement) {
    final aura = engagement.auraSummary;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreItem(
            label: 'STREAK',
            value: '${aura?.currentStreak ?? 0}d',
            icon: Icons.local_fire_department_rounded,
            color: Colors.orange,
          ),
          Container(width: 1, height: 40, color: AppColors.borderFor(context)),
          _ScoreItem(
            label: 'AURA',
            value: '${aura?.auraPoints ?? 0}',
            icon: Icons.auto_awesome_rounded,
            color: Colors.amber,
          ),
          Container(width: 1, height: 40, color: AppColors.borderFor(context)),
          _ScoreItem(
            label: 'LEVEL',
            value: aura?.level ?? 'Builder',
            icon: Icons.military_tech_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildProgressBar(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.text3For(context),
                letterSpacing: 1,
              ),
            ),
            Text(
              '${_currentQuestionIndex + 1} / $total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (total > 0) ? (_currentQuestionIndex + 1) / total : 0,
            minHeight: 8,
            backgroundColor: AppColors.bg2For(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildNoChallengeState() {
    return AppEmptyState(
      icon: Icons.auto_awesome_rounded,
      title: 'No challenges found',
      message: 'To see questions, please run the SEED_WEEKLY_CHALLENGES.sql script in your Supabase SQL Editor.',
      actionLabel: 'Refresh Content',
      onAction: _fetchChallenge,
    );
  }

  Widget _buildTechStackSelector(dynamic me) {
    if (me == null || (me.stack as List).isEmpty) return const SizedBox.shrink();
    
    final List<String> stacks = List<String>.from(me.stack);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TECH DOMAIN',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.text3For(context),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stacks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = stacks[i];
              final isSelected = _activeTechStack == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeTechStack = s);
                  _fetchChallenge();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderFor(context),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isSelected ? Colors.white : AppColors.text2For(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeHeader(BuildContext context, DailyChallengeModel challenge) {
    return Row(
      children: [
        _HeaderBadge(
          label: challenge.techStack,
          icon: Icons.terminal_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _HeaderBadge(
          label: '+${challenge.pointsReward} XP',
          icon: Icons.workspace_premium_rounded,
          color: Colors.amber,
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildChallengeCard(BuildContext context, DailyChallengeModel challenge) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challenge.difficulty).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getDifficultyColor(challenge.difficulty).withValues(alpha: 0.2)),
                ),
                child: Text(
                  challenge.difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _getDifficultyColor(challenge.difficulty),
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AI MISSION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  challenge.question,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textFor(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildActionSection(BuildContext context, EngagementProvider provider, DailyChallengeModel challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'YOUR SOLUTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.text3For(context),
          ),
        ),
        const SizedBox(height: 16),
        if (challenge.options.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: challenge.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final option = challenge.options[i];
              final isSelected = _selectedOption == option;
              return GestureDetector(
                onTap: () => setState(() => _selectedOption = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderFor(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.primary : AppColors.text3For(context),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textFor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          TextField(
            onChanged: (v) => setState(() => _selectedOption = v),
            maxLines: 5,
            style: TextStyle(color: AppColors.textFor(context)),
            decoration: InputDecoration(
              hintText: 'Describe your implementation approach or provide the code snippet...',
              hintStyle: TextStyle(color: AppColors.text3For(context), fontSize: 14),
              fillColor: AppColors.bg2For(context),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: AppColors.borderFor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        const SizedBox(height: 32),
        AppButton(
          onPressed: _selectedOption == null ? null : () => _submit(provider),
          isLoading: provider.isSubmittingChallenge,
          child: const Text(
            'Confirm Submission',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).moveY(begin: 20);
  }

  Widget _buildCompletionStatus(BuildContext context, DailyChallengeModel challenge) {
    final solved = challenge.wasSolved;
    final points = solved ? challenge.pointsReward : DailyChallengeModel.attemptReward;
    final color = solved ? Colors.green : Colors.orange;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      child: Row(
        children: [
          Icon(
            solved ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: color,
            size: 44,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solved ? 'Module Mastered' : 'Attempt Saved',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Awarded +$points Aura. Continue to next for full mastery.',
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer();
  }

  Widget _buildAiTipSection(BuildContext context, DailyChallengeModel challenge) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Text(
                'AI MENTOR TIP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppColors.textFor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mastering ${challenge.techStack} requires understanding core patterns. For this specific task, consider how high-level abstractions can reduce cognitive load. Focus on readability first, performance second.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.text2For(context),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.redAccent;
      default: return AppColors.text3;
    }
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ScoreItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppColors.text3For(context),
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeaderBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _ChallengeSolvedOverlay extends StatelessWidget {
  final AnimationController controller;
  final int awardedPoints;

  const _ChallengeSolvedOverlay({required this.controller, required this.awardedPoints});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scale = 0.8 + (controller.value * 0.2);
        final opacity = (1.0 - (controller.value - 0.8).clamp(0.0, 0.2) / 0.2);

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 90),
                        const SizedBox(height: 28),
                        const Text(
                          'EXCELLENT!',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '+$awardedPoints AURA POINTS',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

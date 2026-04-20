import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/daily_challenge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/info_block.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  String? _selectedOption;
  Timer? _midnightRefreshTimer;
  Timer? _successOverlayTimer;
  String _activeDateKey = _dateKeyFor(DateTime.now());
  late final AnimationController _successController;
  bool _showSuccessOverlay = false;
  int _celebrationPoints = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _midnightRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshIfDateChanged(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightRefreshTimer?.cancel();
    _successOverlayTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDateChanged();
    }
  }

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

      if (solved) {
        _playSuccessOverlay(awardedPoints);
      }

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
      });
    });
  }

  Future<void> _refreshIfDateChanged() async {
    final nextDateKey = _dateKeyFor(DateTime.now());
    if (nextDateKey == _activeDateKey || !mounted) return;

    _activeDateKey = nextDateKey;
    _selectedOption = null;

    await context.read<EngagementProvider>().fetchOverview(
          forceChallengeRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;

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
                  child: Consumer<EngagementProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading && provider.dailyChallenge == null) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
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
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMissionHeader(context, me),
                            const SizedBox(height: 16),
                            _buildMainCard(context, daily),
                            const SizedBox(height: 16),
                            if (!daily.completed) _buildActionSection(context, provider),
                            if (daily.completed) _buildCompletionStatus(context, daily),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessOverlay)
            Positioned.fill(
              child: _MissionSolvedOverlay(
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
      expandedHeight: 80, // Reduced from 120
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
            fontSize: 20, // Reduced from 24
            color: AppColors.textFor(context),
            letterSpacing: -0.5,
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
        ).animate().fadeIn().slideX(begin: -0.1),
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
          const SizedBox(height: 14),
          Text(
            challenge.title,
            style: TextStyle(
              fontSize: 20, // Reduced from 24
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 14, // Reduced from 16
              height: 1.5,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 14),
          InfoBlock(
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
          const SizedBox(height: 10),
          InfoBlock(
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
          spacing: 12,
          runSpacing: 12,
          children: challenge.options
              .map(
                (option) => _PhysicalOption(
                  label: option,
                  isSelected: _selectedOption == option,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedOption = option;
                    });
                  },
                ),
              )
              .toList(),
        ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1),
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

  static String _dateKeyFor(DateTime dateTime) =>
      dateTime.toIso8601String().split('T').first;
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

class _MissionSolvedOverlay extends StatelessWidget {
  final AnimationController controller;
  final int awardedPoints;

  const _MissionSolvedOverlay({
    required this.controller,
    required this.awardedPoints,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final fade = (1 - (controller.value - 0.85).clamp(0.0, 0.15) / 0.15)
              .clamp(0.0, 1.0);

          // Bouncy entrance logic inspired by Duolingo
          double scale = 0.0;
          if (controller.value < 0.3) {
            scale = Curves.elasticOut.transform(controller.value / 0.3) * 1.1;
          } else {
            scale = 1.1 - (controller.value - 0.3) * 0.1;
          }
          if (scale < 1.0) scale = 1.0;

          return Opacity(
            opacity: fade,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85 * fade),
              ),
              child: Stack(
                children: [
                  ...List.generate(
                    24,
                    (index) => _CelebrationParticle(
                      controller: controller,
                      index: index,
                    ),
                  ),
                  Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Mission Accomplished!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '+$awardedPoints Aura points',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhysicalOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PhysicalOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected 
        ? AppColors.primary 
        : AppColors.borderFor(context);
    
    final shadowColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isSelected ? 4 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected 
            ? [] 
            : [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textFor(context),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CelebrationParticle extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _CelebrationParticle({
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final left = ((index * 37) % 100) / 100;
    final size = 10.0 + (index % 5) * 6.0;
    final startY = -0.12 - ((index % 4) * 0.08);
    final endY = 1.05 + ((index % 3) * 0.08);
    final drift = ((index % 6) - 2.5) * 0.03;
    final turns = ((index % 5) + 1) * 0.22;
    final colors = <Color>[
      const Color(0xFFFFD54F),
      const Color(0xFFFF7043),
      const Color(0xFF4DD0E1),
      const Color(0xFF81C784),
      const Color(0xFFBA68C8),
    ];
    final color = colors[index % colors.length];

    return Align(
      alignment: Alignment(left * 2 - 1, 0),
      child: FractionalTranslation(
        translation: Offset(
          drift * controller.value * 10,
          startY + ((endY - startY) * controller.value),
        ),
        child: Transform.rotate(
          angle: controller.value * turns * 6.28318,
          child: Container(
            width: size,
            height: size * (index.isEven ? 1.6 : 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(index.isEven ? 3 : size),
            ),
          ),
        ),
      ),
    );
  }
}

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
          const SizedBox(height: 14),
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
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final fade = (1 - (controller.value - 0.82).clamp(0.0, 0.18) / 0.18)
              .clamp(0.0, 1.0);

          return Opacity(
            opacity: fade,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC07111F),
                    Color(0xF0142B46),
                    Color(0xF0050A12),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  ...List.generate(
                    18,
                    (index) => _CelebrationParticle(
                      controller: controller,
                      index: index,
                    ),
                  ),
                  Center(
                    child: Transform.scale(
                      scale: 0.82 + (curved.value * 0.18),
                      child: Opacity(
                        opacity: curved.value.clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 30,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF7B733),
                                Color(0xFFFC4A1A),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF7B733).withValues(alpha: 0.32),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Correct Answer!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '+$awardedPoints Aura added',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Mission completed for today',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Color(0xFFFDF1E3),
                                ),
                              ),
                            ],
                          ),
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

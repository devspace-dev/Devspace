import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
            child: Consumer<EngagementProvider>(
              builder: (context, provider, _) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context),
                    if (provider.isLoading && provider.dailyChallenge == null)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else if (provider.dailyChallenge == null)
                      const SliverFillRemaining(
                        child: AppEmptyState(
                          icon: Icons.auto_awesome_rounded,
                          title: 'No mission today',
                          message: 'Check back tomorrow for a new mission.',
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Builder(
                          builder: (context) {
                            final daily = provider.dailyChallenge!;
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
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMissionHeader(context, me),
                                  const SizedBox(height: 24),
                                  _buildMainCard(context, daily),
                                  const SizedBox(height: 32),
                                  if (!daily.completed) _buildActionSection(context, provider),
                                  if (daily.completed) _buildCompletionStatus(context, daily),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
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
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'Daily Mission',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w900,
          fontSize: 24,
          color: AppColors.textFor(context),
          letterSpacing: -0.5,
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
          label: '${me?.currentStreak ?? 0} DAY STREAK',
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
        ).animate().fadeIn().slideX(begin: -0.1),
        const _HeaderBadge(
          label: '+20 SOLVE / +5 TRY',
          icon: Icons.bolt_rounded,
          color: AppColors.primary,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
      ],
    );
  }


  Widget _buildMainCard(BuildContext context, DailyChallengeModel challenge) {
    final showDescription = challenge.description.trim() != challenge.question.trim();

    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  challenge.techStack.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              AppBadge(
                label: challenge.difficulty.toUpperCase(),
                color: _getDifficultyColor(challenge.difficulty),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            challenge.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          if (showDescription) ...[
            const SizedBox(height: 14),
            Text(
              challenge.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.text2For(context),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg3For(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.question,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: AppColors.textFor(context),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.text3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solve this to boost your aura and maintain your streak.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text3For(context),
                  ),
                ),
              ),
            ],
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
          'SELECT YOUR ANSWER',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.text3For(context),
            letterSpacing: 1.5,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: challenge.options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = challenge.options[index];
            return _PhysicalOption(
              label: option,
              isSelected: _selectedOption == option,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedOption = option;
                });
              },
            );
          },
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
        const SizedBox(height: 32),
        AppButton(
          onPressed: _selectedOption == null ? null : () => _submit(provider),
          isLoading: provider.isSubmittingChallenge,
          child: const Text(
            'Confirm Submission',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            solved ? Icons.verified_rounded : Icons.lock_clock_rounded,
            color: accent,
            size: 48,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solved ? 'Module Solved' : 'Module Attempted',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  solved
                      ? 'You earned +$points Aura points. Your streak stays active.'
                      : 'You earned +$points Aura for trying. This mission is locked until tomorrow.',
                  style: TextStyle(
                    fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
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
                    32,
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
                          horizontal: 32,
                          vertical: 48,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'EXCELLENT!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '+$awardedPoints AURA POINTS',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
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
    final shadowColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isSelected ? 4 : 0, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderFor(context),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] 
            : [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.text3For(context),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textFor(context),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
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
    final size = 8.0 + (index % 5) * 6.0;
    final startY = -0.15 - ((index % 4) * 0.1);
    final endY = 1.1 + ((index % 3) * 0.1);
    final drift = ((index % 6) - 2.5) * 0.04;
    final turns = ((index % 5) + 1) * 0.25;
    final colors = <Color>[
      const Color(0xFFFFD54F),
      const Color(0xFFFF7043),
      const Color(0xFF4DD0E1),
      const Color(0xFF81C784),
      const Color(0xFFBA68C8),
      AppColors.primary,
    ];
    final color = colors[index % colors.length];

    return Align(
      alignment: Alignment(left * 2 - 1, 0),
      child: FractionalTranslation(
        translation: Offset(
          drift * controller.value * 12,
          startY + ((endY - startY) * controller.value),
        ),
        child: Transform.rotate(
          angle: controller.value * turns * 6.28318,
          child: Container(
            width: size,
            height: size * (index.isEven ? 1.8 : 1.2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(index.isEven ? 4 : size),
            ),
          ),
        ),
      ),
    );
  }
}

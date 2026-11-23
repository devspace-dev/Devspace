import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../core/services/reward_feedback.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/aura_chip.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_card.dart';
import '../core/widgets/ds_tag.dart';
import '../core/widgets/glitch.dart';
import '../models/daily_challenge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../services/supabase_service.dart';

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
      if (mounted) {
        try {
          final authP = context.read<AuthProvider>();
          if (provider.auraSummary != null) {
            authP.updateLocalAura(provider.auraSummary!.auraPoints);
          }
        } catch (_) {}
      }
      unawaited(provider.fetchAuraHistory());
      unawaited(SupabaseService.instance.syncMyBadges());
      final challenge = provider.dailyChallenge;
      final solved = challenge?.wasSolved ?? false;
      final awardedPoints =
          solved ? (challenge?.pointsReward ?? 20) : DailyChallengeModel.attemptReward;

      if (solved) {
        RewardFeedback.success();
        _playSuccessOverlay(awardedPoints);
      } else {
        RewardFeedback.medium();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            solved
                ? 'Correct answer. +$awardedPoints Aura added.'
                : 'Wrong answer. +$awardedPoints Aura for attempting. Mission locked until tomorrow.',
            style: DsText.label.copyWith(color: Ds.ink),
          ),
          backgroundColor: solved ? Ds.mint : Ds.hot,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 160,
            left: 16,
            right: 16,
          ),
        ),
      );
      return;
    }

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!, style: DsText.label.copyWith(color: Ds.ink)),
          backgroundColor: Ds.hot,
          behavior: SnackBarBehavior.floating,
        ),
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
    final provider = context.watch<EngagementProvider>();
    final daily = provider.dailyChallenge;
    final canSubmit = daily != null && !daily.completed;

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Ds.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Ds.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Ds.bone, size: 16),
            ),
          ),
        ),
        title: Text(
          'DAILY MISSION',
          style: DsText.h2.copyWith(fontSize: 20, color: Ds.bone),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: AuraChip(me?.aura ?? 0),
            ),
          ),
        ],
      ),
      bottomNavigationBar: canSubmit
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: Ds.ink,
                border: Border(top: BorderSide(color: Ds.border, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  child: DsButton(
                    label: 'CONFIRM SUBMISSION',
                    kind: DsButtonKind.aura,
                    loading: provider.isSubmittingChallenge,
                    onPressed: _selectedOption == null ? null : () => _submit(provider),
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          Consumer<EngagementProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.dailyChallenge == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Ds.aura),
                );
              }

              if (provider.dailyChallenge == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Glitch(size: 80, mood: GlitchMood.idle),
                        const SizedBox(height: 16),
                        Text('NO MISSION TODAY', style: DsText.h3.copyWith(color: Ds.bone)),
                        const SizedBox(height: 8),
                        Text(
                          'Check back tomorrow for a new mission.',
                          textAlign: TextAlign.center,
                          style: DsText.bodySm.copyWith(color: Ds.muted),
                        ),
                      ],
                    ),
                  ),
                );
              }

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

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMissionHeader(context, me),
                    const SizedBox(height: 16),
                    _buildMainCard(context, daily),
                    const SizedBox(height: 24),
                    if (!daily.completed) _buildActionSection(context, provider),
                    if (daily.completed) _buildCompletionStatus(context, daily),
                  ],
                ),
              );
            },
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

  Widget _buildMissionHeader(BuildContext context, dynamic me) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DsTag(
          '${me?.currentStreak ?? 0} DAY STREAK',
          bg: Ds.surface,
          fg: Ds.hot,
        ),
        const DsTag(
          '+20 SOLVE / +5 TRY',
          bg: Ds.aura,
          fg: Ds.ink,
        ),
      ],
    );
  }

  Widget _buildMainCard(BuildContext context, DailyChallengeModel challenge) {
    final showDescription =
        challenge.description.trim() != challenge.question.trim();

    return DsCard(
      leftBar: challenge.completed
          ? (challenge.wasSolved ? Ds.mint : Ds.hot)
          : Ds.aura,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DsTag(
                challenge.techStack.toUpperCase(),
                bg: Ds.surface,
                fg: Ds.aura,
              ),
              DsTag(
                challenge.difficulty.toUpperCase(),
                bg: _getDifficultyColor(challenge.difficulty),
                fg: Ds.ink,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            challenge.title.toUpperCase(),
            style: DsText.h2.copyWith(fontSize: 22, color: Ds.bone, height: 1.15),
          ),
          if (showDescription) ...[
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: DsText.body.copyWith(
                fontSize: 14,
                height: 1.5,
                color: Ds.muted,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildQuestionContent(challenge.question),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Ds.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Solve this to boost your aura and maintain your streak.',
                  style: DsText.caption.copyWith(color: Ds.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildQuestionContent(String rawQuestion) {
    final trimmed = rawQuestion.trim();
    if (!trimmed.contains('```')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Ds.ink,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Ds.border),
        ),
        child: Text(
          trimmed,
          style: DsText.body.copyWith(
            fontSize: 15,
            height: 1.5,
            color: Ds.bone,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final parts = trimmed.split('```');
    final widgets = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isEmpty) continue;

      if (i % 2 == 1) {
        // Monospace code block with horizontal scrolling
        String code = part;
        final firstNewline = code.indexOf('\n');
        if (firstNewline != -1) {
          final firstWord = code.substring(0, firstNewline).trim();
          if (firstWord.isNotEmpty && !firstWord.contains(' ') && firstWord.length < 15) {
            code = code.substring(firstNewline + 1);
          }
        }

        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Ds.ink,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ds.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Text(
                code.trimRight(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  color: Ds.aura,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      } else {
        // Prose block wrapping naturally to width
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              part.trim(),
              style: DsText.body.copyWith(
                fontSize: 15,
                height: 1.5,
                color: Ds.bone,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Ds.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Ds.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, EngagementProvider provider) {
    final challenge = provider.dailyChallenge;
    if (challenge == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT YOUR ANSWER',
          style: DsText.label.copyWith(fontSize: 11, color: Ds.muted, letterSpacing: 1.5),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 14),
        ...List.generate(challenge.options.length, (index) {
          final option = challenge.options[index];
          final letter = String.fromCharCode(65 + index);
          final isSelected = _selectedOption == option;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                RewardFeedback.selection();
                setState(() {
                  _selectedOption = option;
                });
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Ds.surface : Ds.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Ds.aura : Ds.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Ds.aura : Ds.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: DsText.caption.copyWith(
                          color: isSelected ? Ds.ink : Ds.bone,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: DsText.body.copyWith(
                          color: isSelected ? Ds.aura : Ds.bone,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle_rounded, color: Ds.aura, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: DsText.caption.copyWith(color: Ds.hot, fontWeight: FontWeight.w600),
          ),
        ],
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

    return DsCard(
      leftBar: solved ? Ds.mint : Ds.hot,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Glitch(
            size: 56,
            mood: solved ? GlitchMood.win : GlitchMood.lose,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solved ? 'MISSION SOLVED' : 'MISSION ATTEMPTED',
                  style: DsText.h3.copyWith(
                    fontSize: 16,
                    color: solved ? Ds.mint : Ds.hot,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  solved
                      ? 'You earned +$points Aura points. Your streak stays active.'
                      : 'You earned +$points Aura for attempting. This mission is locked until tomorrow.',
                  style: DsText.bodySm.copyWith(
                    color: Ds.bone,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Ds.mint;
      case 'medium':
        return Ds.aura;
      case 'hard':
        return Ds.hot;
      default:
        return Ds.border;
    }
  }

  static String _dateKeyFor(DateTime dateTime) {
    final ist = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
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
              color: Ds.ink.withValues(alpha: 0.88 * fade),
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
                          horizontal: 28,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          color: Ds.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Ds.mint, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Glitch(
                              size: 80,
                              mood: GlitchMood.win,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'BIG BRAIN!',
                              textAlign: TextAlign.center,
                              style: DsText.h1.copyWith(
                                fontSize: 28,
                                color: Ds.bone,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Ds.mint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+$awardedPoints AURA POINTS',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Ds.ink,
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
    const colors = <Color>[
      Ds.aura,
      Ds.mint,
      Ds.hot,
      Ds.bone,
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

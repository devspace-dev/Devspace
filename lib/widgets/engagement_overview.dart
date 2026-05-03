import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daily_challenge_model.dart';
import '../providers/engagement_provider.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/opportunities_screen.dart';
import '../screens/aura_board_screen.dart';
import '../screens/aura_history_screen.dart';
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
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SectionCard(
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Loading your aura, streak, and opportunities...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text2For(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
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
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.bg2For(context),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DashboardAction(
                              icon: Icons.history_rounded,
                              title: 'Aura History',
                              subtitle: 'See how you earned your points.',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuraHistoryScreen()));
                              },
                            ),
                            const SizedBox(height: 12),
                            _DashboardAction(
                              icon: Icons.leaderboard_rounded,
                              title: 'Global Leaderboard',
                              subtitle: 'See how you rank against other builders.',
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuraBoardScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: _NeonStatsCard(
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
              ),
            if (challenge != null && !challenge.wasSolved)
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
                              'Daily Mission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textFor(context),
                              ),
                            ),
                          ),
                          Text(
                            challenge.wasSolved
                                ? 'Solved'
                                : challenge.wasAttempted
                                    ? 'Attempted'
                                    : '+${challenge.pointsReward} / +${DailyChallengeModel.attemptReward} aura',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: challenge.wasSolved
                                  ? Colors.green
                                  : challenge.wasAttempted
                                      ? Colors.orange
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
                        challenge.question,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.text2For(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${challenge.techStack} - ${challenge.missionType}',
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (provider.events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OpportunitiesScreen(),
                      ),
                    );
                  },
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
              ),
          ],
        );
      },
    );
  }

}

class _NeonStatsCard extends StatefulWidget {
  final Widget child;

  const _NeonStatsCard({required this.child});

  @override
  State<_NeonStatsCard> createState() => _NeonStatsCardState();
}

class _NeonStatsCardState extends State<_NeonStatsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final hue = _controller.value * 360;
          final leading = HSVColor.fromAHSV(1, hue, 0.82, 1).toColor();
          final trailing =
              HSVColor.fromAHSV(1, (hue + 70) % 360, 0.78, 1).toColor();

          return Container(
            padding: const EdgeInsets.all(1.4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  leading.withValues(alpha: 0.95),
                  trailing.withValues(alpha: 0.85),
                  AppColors.primary.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: leading.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _SectionCard(
              child: widget.child,
            ),
          );
        },
      ),
    );
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
    final numericValue = int.tryParse(value);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.mint.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: numericValue ?? 0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(
                numericValue == null ? value : '$animatedValue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: AppColors.textFor(context),
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: AppColors.text3For(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg3For(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text3For(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.text4For(context), size: 14),
          ],
        ),
      ),
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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/daily_challenge_model.dart';
import '../providers/engagement_provider.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/opportunities_screen.dart';
import '../screens/opportunity_detail_screen.dart';
import '../screens/aura_board_screen.dart';
import '../screens/aura_history_screen.dart';
import '../theme/app_colors.dart';

import '../providers/auth_provider.dart';
import 'app_ui_kit.dart';

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
                  child: _SectionCard(
                    highlighted: true,
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
                child: _PremiumMissionCard(
                  challenge: challenge,
                  provider: provider,
                ),
              ),
            if (challenge == null && !provider.isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SectionCard(
                  child: Column(
                    children: [
                      const Center(
                        child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No mission today',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check back later for a new mission.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text3For(context),
                        ),
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'The Hub',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Explore', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...provider.unlockedEvents.take(3).map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OpportunityDetailScreen(opportunity: event),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: event.type.toLowerCase() == 'hackathon' ? Colors.purpleAccent : AppColors.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textFor(context),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${event.type.toUpperCase()} • ${event.organizer ?? 'DevSpace'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text3For(context),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.text4),
                                    ],
                                  ),
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

  void _confirmDeleteChallenge(BuildContext context, EngagementProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge?'),
        content: const Text('This will remove the challenge for everyone. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteDailyChallenge(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, EngagementProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This will remove the event/opportunity for everyone. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteEvent(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PremiumMissionCard extends StatelessWidget {
  final DailyChallengeModel challenge;
  final EngagementProvider provider;

  const _PremiumMissionCard({
    required this.challenge,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFounder = context.read<AuthProvider>().currentUserOrNull?.isFounder == true;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily Mission',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context),
                ),
              ),
              const Spacer(),
              Text(
                challenge.wasAttempted ? 'Attempted' : '+${challenge.pointsReward} aura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: challenge.wasAttempted ? Colors.orange : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            challenge.question,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.techStack.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3For(context),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2For(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isFounder)
                IconButton(
                  onPressed: () => const EngagementOverview()._confirmDeleteChallenge(context, provider, challenge.challengeId),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              AppButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DailyChallengeScreen(),
                    ),
                  );
                },
                width: 84,
                height: 38,
                borderRadius: 12,
                child: const Text(
                  'Solve',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.textFor(context),
          ),
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
                color: AppColors.primary.withValues(alpha: 0.1),
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
  final bool highlighted;

  const _SectionCard({
    required this.child,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return _RgbOutlineCard(child: child);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderFor(context).withValues(alpha: 0.8),
        ),
      ),
      child: child,
    );
  }
}

class _RgbOutlineCard extends StatefulWidget {
  final Widget child;

  const _RgbOutlineCard({required this.child});

  @override
  State<_RgbOutlineCard> createState() => _RgbOutlineCardState();
}

class _RgbOutlineCardState extends State<_RgbOutlineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: SweepGradient(
              transform: GradientRotation(_controller.value * math.pi * 2),
              colors: const [
                Color(0xFFFF4D6D),
                Color(0xFFFFD166),
                Color(0xFF06D6A0),
                Color(0xFF00D1FF),
                Color(0xFF8B5CF6),
                Color(0xFFFF4D6D),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(radius - 1),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

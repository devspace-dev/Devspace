import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/glitch.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../../../screens/daily_challenge_screen.dart';
import '../../../screens/notifications_screen.dart';
import '../../../screens/duel_mode_landing_screen.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserOrNull;
    final engagement = context.watch<EngagementProvider>();
    final aura = user?.aura ?? 0;
    final streak = (user?.currentStreak ?? 0) > 0 ? user!.currentStreak : 1;
    final name = (user?.name ?? 'Builder').split(' ').first;
    final mission = engagement.dailyChallenge;
    final hasMission = mission != null && !mission.completed;

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('DEVSPACE', style: DsText.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Ds.bone, size: 24),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakChip(streak),
                const SizedBox(width: 8),
                AuraChip(aura),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mascot / Glitch Speech Bubble
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Glitch(size: 64, mood: hasMission ? GlitchMood.hype : GlitchMood.idle),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Ds.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                        bottomLeft: Radius.circular(2),
                      ),
                      border: Border.all(color: Ds.border, width: 2),
                    ),
                    child: Text(
                      hasMission
                          ? 'Day $streak streak, $name. Do not ruin it.'
                          : 'No mission today. Touch grass, or practice.',
                      style: DsText.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Daily Puzzles Card
            DsCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Ds.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Ds.aura, width: 2),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Ds.aura, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY PUZZLE', style: DsText.caption.copyWith(color: Ds.aura)),
                        const SizedBox(height: 2),
                        Text(
                          mission?.title ?? 'Daily puzzle: mate in 2',
                          style: DsText.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${mission?.pointsReward ?? 10}',
                    style: DsText.number.copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Ds.muted),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Solo mode (easy, medium, hard, ultra)
            Text('QUEUE UP', style: DsText.h3),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildLobbyTile(
                  context: context,
                  title: 'NOOB LOBBY',
                  level: 'EASY',
                  tierColor: Ds.tierBronze,
                  reward: '+5 AURA',
                  lobbyId: 'noob',
                ),
                _buildLobbyTile(
                  context: context,
                  title: 'SCRIMS',
                  level: 'MEDIUM',
                  tierColor: Ds.tierSilver,
                  reward: '+10 AURA',
                  lobbyId: 'scrims',
                ),
                _buildLobbyTile(
                  context: context,
                  title: 'RANKED',
                  level: 'HARD',
                  tierColor: Ds.tierGold,
                  reward: '+15 AURA',
                  lobbyId: 'ranked',
                ),
                _buildLobbyTile(
                  context: context,
                  title: 'FINAL CIRCLE',
                  level: 'ULTRA',
                  tierColor: Ds.tierGem,
                  reward: '+20 AURA',
                  lobbyId: 'final_circle',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Combat mode (reflex first, code combat second)
            Text('COMBAT', style: DsText.h3),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildCombatTile(
                  context: context,
                  title: 'REFLEX 1v1',
                  tag: 'BLITZ',
                  accentColor: Ds.hot,
                  reward: '+25 AURA',
                  mode: 'REFLEX MODE',
                ),
                _buildCombatTile(
                  context: context,
                  title: 'CODE COMBAT',
                  tag: 'DUEL',
                  accentColor: Ds.aura,
                  reward: '+50 AURA',
                  mode: 'CODE COMBAT',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Continue Path at the end
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DsTag('CONTINUE PATH', bg: Ds.border, fg: Ds.bone),
                      Icon(Icons.route_outlined, color: Ds.aura, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('REACT & STATE MANAGEMENT', style: DsText.h3),
                  const SizedBox(height: 4),
                  Text('Step 4 of 7 · +40 Aura on completion', style: DsText.bodySm),
                  const SizedBox(height: 14),
                  DsButton(
                    label: 'Continue',
                    kind: DsButtonKind.aura,
                    onPressed: () => context.go('/path'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyTile({
    required BuildContext context,
    required String title,
    required String level,
    required Color tierColor,
    required String reward,
    required String lobbyId,
  }) {
    return DsCard(
      leftBar: tierColor,
      onTap: () => context.push('/quiz/$lobbyId'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DsTag(level, bg: tierColor, fg: Ds.ink),
          Text(title, style: DsText.h3.copyWith(fontSize: 18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reward, style: DsText.number.copyWith(fontSize: 16)),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Ds.muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombatTile({
    required BuildContext context,
    required String title,
    required String tag,
    required Color accentColor,
    required String reward,
    required String mode,
  }) {
    return DsCard(
      leftBar: accentColor,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuelModeLandingScreen(
              category: 'Combat',
              mode: mode,
              color: accentColor,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DsTag(tag, bg: accentColor, fg: Ds.ink),
          Text(title, style: DsText.h3.copyWith(fontSize: 18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reward, style: DsText.number.copyWith(fontSize: 16)),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Ds.muted),
            ],
          ),
        ],
      ),
    );
  }
}

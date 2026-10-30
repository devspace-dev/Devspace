import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../screens/profile_setup_screen.dart';
import '../../../screens/saved_posts_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  @override
  Widget build(BuildContext context) {
    final authP = context.watch<AuthProvider>();
    final user = authP.currentUserOrNull;
    final usersP = context.watch<UsersProvider>();
    final practiceP = context.watch<PracticeProvider?>();
    final streak = (user?.currentStreak ?? 0) > 0 ? user!.currentStreak : 1;
    final aura = user?.aura ?? 0;
    final rankTitle = getRankTag(aura);
    final solvedCount = (practiceP != null && practiceP.totalCompletedCount > 0)
        ? practiceP.totalCompletedCount
        : (aura / 25).floor();

    // Compute college rank
    final collegeUsers = usersP.users
        .where((u) => u.college.isNotEmpty && u.college == user?.college)
        .toList()
      ..sort((a, b) => b.aura.compareTo(a.aura));
    final collegeRank = user != null ? collegeUsers.indexWhere((u) => u.id == user.id) + 1 : 0;
    final collegeRankDisplay = collegeRank > 0 ? '#$collegeRank' : '--';

    final stack = (user?.stack != null && user!.stack.isNotEmpty)
        ? user.stack
        : const ['Flutter', 'PostgreSQL', 'Dart'];

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('PROFILE', style: DsText.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AuraChip(aura),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Avatar with 72px yellow ring
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Ds.aura, width: 3),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: Ds.surface,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                    style: DsText.h2.copyWith(color: Ds.bone),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.name ?? 'Developer', style: DsText.h2),
            const SizedBox(height: 4),
            Text('@${user?.handle ?? "dev"}', style: DsText.bodySm),
            const SizedBox(height: 8),
            DsTag(rankTitle, bg: Ds.aura, fg: Ds.ink),
            const SizedBox(height: 20),

            // Three Stat Cards (Streak in coral, College Rank in yellow, Solved in mint)
            Row(
              children: [
                Expanded(
                  child: DsCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 20, color: Ds.hot),
                            const SizedBox(width: 4),
                            Text('$streak', style: DsText.number.copyWith(fontSize: 22, color: Ds.hot)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('STREAK', style: DsText.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DsCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 20, color: Ds.aura),
                            const SizedBox(width: 4),
                            Text(collegeRankDisplay, style: DsText.number.copyWith(fontSize: 22, color: Ds.aura)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('COLLEGE RANK', style: DsText.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DsCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20, color: Ds.mint),
                            const SizedBox(width: 4),
                            Text('$solvedCount', style: DsText.number.copyWith(fontSize: 22, color: Ds.mint)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('SOLVED', style: DsText.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Badge Row
            DsCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BADGES', style: DsText.label),
                      Text('5 TOTAL', style: DsText.caption),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(
                        title: 'First Build',
                        icon: Icons.code_rounded,
                        earned: aura >= 10,
                      ),
                      _buildBadge(
                        title: 'Week Fire',
                        icon: Icons.local_fire_department_rounded,
                        earned: streak >= 7,
                      ),
                      _buildBadge(
                        title: 'Century',
                        icon: Icons.bolt_rounded,
                        earned: aura >= 100,
                      ),
                      _buildBadge(
                        title: 'Veteran',
                        icon: Icons.military_tech_rounded,
                        earned: aura >= 500,
                      ),
                      _buildBadge(
                        title: '10x Dev',
                        icon: Icons.auto_awesome_rounded,
                        earned: aura >= 1500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tech Stack Chips
            DsCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TECH STACK', style: DsText.label),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stack.map((tech) => DsTag(tech, bg: Ds.border, fg: Ds.bone)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Edit Profile Button (Bone kind)
            DsButton(
              label: 'Edit Profile',
              kind: DsButtonKind.bone,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSetupScreen(mode: ProfileSetupMode.edit),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Settings & Actions Rows
            DsCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bookmark_border_rounded, color: Ds.bone),
                      title: Text('Saved Posts', style: DsText.label),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Ds.muted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Ds.border),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined, color: Ds.bone),
                      title: Text('Theme', style: DsText.label),
                      trailing: Text('Dark (v1)', style: DsText.caption.copyWith(color: Ds.aura)),
                    ),
                    const Divider(height: 1, color: Ds.border),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Ds.hot),
                      title: Text('Sign Out', style: DsText.label.copyWith(color: Ds.hot)),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Ds.surface,
                            title: Text('SIGN OUT', style: DsText.h3),
                            content: Text('Are you sure you want to sign out?', style: DsText.body),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('CANCEL', style: DsText.button.copyWith(color: Ds.muted)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('SIGN OUT', style: DsText.button.copyWith(color: Ds.hot)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await authP.signOut();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String title,
    required IconData icon,
    required bool earned,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: earned ? Ds.surface : Ds.ink,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: earned ? Ds.aura : Ds.border,
              width: earned ? 2 : 1,
            ),
          ),
          child: Icon(
            earned ? icon : Icons.lock_outline_rounded,
            size: 22,
            color: earned ? Ds.aura : Ds.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: DsText.caption.copyWith(
            fontSize: 10,
            color: earned ? Ds.bone : Ds.muted,
            fontWeight: earned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

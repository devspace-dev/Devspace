import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/roadmap_model.dart';
import '../providers/auth_provider.dart';
import '../screens/aura_board_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/founder_tools_screen.dart';
import '../screens/learning_roadmap_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/weekly_challenge_pricing_screen.dart';
import '../screens/practice_map_screen.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';

class DevSpaceDrawer extends StatelessWidget {
  const DevSpaceDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: AppColors.bgFor(context),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Drawer Header - User Info
            if (me != null)
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderFor(context).withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      UserAvatar(user: me, size: 50, showRing: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textFor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${me.handle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.text3For(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⚡', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${me.aura} Aura',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.text3For(context),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Main Scrollable List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  // --- Resources For You Section ---
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8, bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resources for you',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.text3For(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...kLearningRoadmaps.map((roadmap) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.bg2For(context),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LearningRoadmapScreen(roadmap: roadmap),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: roadmap.color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    roadmap.icon,
                                    color: roadmap.color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roadmap.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textFor(context),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        roadmap.subtitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.text3For(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.text4For(context),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  Divider(
                    color: AppColors.borderFor(context).withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // --- Quick Navigation Section ---
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Explore & Challenges',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.text3For(context),
                      ),
                    ),
                  ),

                  _DrawerTile(
                    icon: Icons.map_rounded,
                    iconColor: const Color(0xFF00E676),
                    title: 'Practice Track',
                    subtitle: '4 levels (80 Qs) • Untimed',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PracticeMapScreen(),
                        ),
                      );
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.today_rounded,
                    title: 'Daily Challenge',
                    subtitle: 'Solve daily coding task',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyChallengeScreen(),
                        ),
                      );
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.code_rounded,
                    title: 'Weekly Challenge',
                    subtitle: 'Submit PR & earn aura',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyChallengePricingScreen(),
                        ),
                      );
                    },
                  ),

                  _DrawerTile(
                    icon: Icons.bolt_rounded,
                    title: 'Aura Leaderboard',
                    subtitle: 'See top student builders',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuraBoardScreen(),
                        ),
                      );
                    },
                  ),

                  if (me != null && (me.isAdmin || me.isFounder)) ...[
                    const SizedBox(height: 8),
                    _DrawerTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.amber,
                      title: 'Founder Tools',
                      subtitle: 'Community admin controls',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FounderToolsScreen(
                              mode: FounderToolsMode.founderTools,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // 3. Footer Options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderFor(context).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DevSpace v1.0.0 · Student Builders',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text4For(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textFor(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.text3For(context),
              ),
            )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

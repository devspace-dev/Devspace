import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'aura_board_screen.dart';
import 'duel_mode_landing_screen.dart';
import 'daily_challenge_screen.dart';
import 'practice_map_screen.dart';
import '../providers/practice_provider.dart';
import '../data/practice_questions.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _arenaCategories = [
    {
      'name': 'Practice',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF00E676), // Bright Emerald Green
      'score': 'Levels',
      'cards': [
        {
          'title': 'Daily Mission',
          'subtitle':
              'Attempt a daily logical question and get some aura boost.',
          'mode': 'DAILY MISSION',
          'icon': Icons.emoji_events_rounded,
          'duration': '24 Hrs',
          'difficulty': 'Daily',
          'reward': '+100 Aura',
          'tag': 'Daily',
        },
        {
          'title': 'Practice Track',
          'subtitle':
              'Easy → Medium → Hard → Ultra. Practice questions at your own pace.',
          'mode': 'PRACTICE MODE',
          'icon': Icons.route_rounded,
          'duration': 'Untimed',
          'difficulty': '4 Levels',
          'reward': 'Level Map',
          'tag': 'Practice',
        },
      ]
    },
    {
      'name': 'Combat',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFFFD300), // Bright Yellow/Orange Accent
      'score': '1013',
      'cards': [
        {
          'title': 'Reflex Mode',
          'subtitle': 'Quick code. Quick hands.\nFastest fingers win.',
          'mode': 'REFLEX MODE',
          'icon': Icons.bolt_rounded,
          'duration': '1 Min',
          'difficulty': 'Medium',
          'reward': '+25 Aura',
          'tag': 'Live',
        },
        {
          'title': 'Code Combat',
          'subtitle': 'Be the first to answer each technical question.',
          'mode': 'CODE COMBAT',
          'icon': Icons.terminal_rounded,
          'duration': '1 Min',
          'difficulty': 'Hard',
          'reward': '+50 Aura',
          'tag': 'Ranked',
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EngagementProvider>().fetchOverview();
      context.read<UsersProvider>().fetchUsers();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context
          .read<EngagementProvider>()
          .fetchOverview(forceChallengeRefresh: true),
      context.read<UsersProvider>().fetchUsers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;

    if (me == null) {
      return const SizedBox.shrink();
    }

    final category = _arenaCategories[_selectedCategoryIndex];
    final categoryName = (category['name'] as String).toUpperCase();
    final categoryColor = category['color'] as Color;
    final cards = category['cards'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title & Subtitle Header
                Text(
                  'Arena',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compete. Solve. Climb.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3For(context),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Profile Card
                _buildProfileCard(context, me),
                const SizedBox(height: 20),

                // 3. Category Selector Grid (Combat, Daily Challenge, Practice)
                _buildOptionCards(context),
                const SizedBox(height: 20),

                if (_selectedCategoryIndex == 0) ...[
                  // Practice Mode Tab Selected (Index 0: Daily Mission merged + Practice levels)
                  _buildLiveGameCard(
                    context,
                    categoryName: 'PRACTICE',
                    title: 'Daily Mission',
                    subtitle:
                        'Attempt a daily logical question and get some aura boost.',
                    accentColor: const Color(0xFFFF375F),
                    cardIcon: Icons.emoji_events_rounded,
                    duration: '24 Hrs',
                    difficulty: 'Daily',
                    reward: '+100 Aura',
                    tag: 'Daily',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyChallengeScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSharpenYourSkillsSection(context),
                ] else ...[
                  // Combat Tab Selected (Index 1 - Last)
                  Text(
                    'Live Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textFor(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Duel Cards list for Combat category wrapped in Column
                  Column(
                    children: cards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final card = entry.value;
                      return _buildLiveGameCard(
                        context,
                        categoryName: categoryName,
                        title: card['title'] as String,
                        subtitle: card['subtitle'] as String,
                        accentColor: categoryColor,
                        cardIcon: card['icon'] as IconData,
                        duration: card['duration'] as String,
                        difficulty: card['difficulty'] as String,
                        reward: card['reward'] as String,
                        tag: card['tag'] as String,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DuelModeLandingScreen(
                                category: categoryName,
                                mode: card['mode'] as String,
                                color: categoryColor,
                              ),
                            ),
                          );
                        },
                      )
                      .animate(key: ValueKey('${_selectedCategoryIndex}_$index'))
                      .fadeIn(duration: 350.ms, delay: (index * 80).ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 350.ms,
                        delay: (index * 80).ms,
                        curve: Curves.easeOutQuad,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileCard(BuildContext context, UserModel me) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AuraBoardScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderFor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with orange checkmark badge overlay
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(user: me, size: 50),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316), // Orange checkmark background
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Name and handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${me.handle}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: AppColors.borderFor(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 18),
          // Stats row: Aura | Win Streak | Rank
          Row(
            children: [
              Expanded(
                child: _buildProfileStat(
                  label: 'Aura',
                  value: '${me.aura}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.borderFor(context).withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildProfileStat(
                  label: 'Daily Streak',
                  value: '${me.currentStreak}',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildProfileStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text3For(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSharpenYourSkillsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sharpen Your Skills',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a level to start solving problems.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text3For(context),
          ),
        ),
        const SizedBox(height: 20),

        // 4 Practice Level Cards: Easy (120 XP), Medium (250 XP), Hard (500 XP), Ultra (1000+ XP)
        ...PracticeLevelData.levels.map((level) {
          final int levelIndex = level['index'] as int;
          final String name = level['name'] as String;
          final String tagline = level['tagline'] as String;
          final String xp = level['xp'] as String;
          final Color color = Color(level['color'] as int);

          IconData iconData;
          switch (levelIndex) {
            case 0:
              iconData = Icons.battery_charging_full_rounded;
              break;
            case 1:
              iconData = Icons.bolt_rounded;
              break;
            case 2:
              iconData = Icons.local_fire_department_rounded;
              break;
            case 3:
              iconData = Icons.all_inclusive_rounded;
              break;
            default:
              iconData = Icons.star_rounded;
          }

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.read<PracticeProvider>().setSelectedSection(levelIndex);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PracticeMapScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.borderFor(context).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Icon on left, XP Pill on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Level Icon inside circular container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                iconData,
                                color: color,
                                size: 24,
                              ),
                            ),
                          ),
                          // XP Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.bg3For(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.borderFor(context)
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            child: Text(
                              xp,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text2For(context),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Level Title
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle / Tagline
                      Text(
                        tagline,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text3For(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOptionCards(BuildContext context) {
    final engagement = context.watch<EngagementProvider>();
    final history = engagement.auraHistory;
    final scoreReady = !engagement.isLoading || history.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_arenaCategories.length, (index) {
        final cat = _arenaCategories[index];
        final isSelected = _selectedCategoryIndex == index;
        final color = cat['color'] as Color;
        final bool isComingSoon = cat['comingSoon'] == true;

        // Calculate dynamic score based on the category name
        int dynamicScore = 0;
        final String name = cat['name'] as String;
        if (name == 'Combat') {
          dynamicScore = history.where((e) {
            return e.action == 'arena_duel';
          }).fold(0, (sum, e) => sum + e.points);
        } else if (name == 'Practice') {
          final practicePts = context.watch<PracticeProvider>().totalAuraEarned;
          final missionPts = history.where((e) {
            return e.action == 'daily_challenge' ||
                e.action == 'daily_mission_attempt' ||
                e.action == 'mission_solved' ||
                e.action == 'mission_attempted';
          }).fold(0, (sum, e) => sum + e.points);
          dynamicScore = practicePts + missionPts;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == _arenaCategories.length - 1 ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              height: 125,
              decoration: BoxDecoration(
                color: AppColors.bg2For(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : AppColors.borderFor(context).withValues(alpha: 0.5),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 26,
                    color: isSelected ? color : AppColors.text2For(context),
                  ),
                  Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.textFor(context)
                          : AppColors.text3For(context),
                    ),
                  ),
                  if (!isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sports_esports_rounded,
                            size: 10,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          scoreReady
                              ? Text(
                                  dynamicScore.toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : SizedBox(
                                  width: 10,
                                  height: 9,
                                  child: Center(
                                    child: SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.4,
                                        color: Colors.black.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Coming Soon',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.text3For(context),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            )
            .animate(target: isSelected ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 200.ms,
              curve: Curves.easeOutBack,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLiveGameCard(
    BuildContext context, {
    required String categoryName,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData cardIcon,
    required String duration,
    required String difficulty,
    required String reward,
    required String tag,
    required VoidCallback onTap,
  }) {
    final bool isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.04 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bg2For(context),
              accentColor.withValues(alpha: isDark ? 0.02 : 0.06),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category details (Only Icon & Name, no tag badge)
              Row(
                children: [
                  // Mode Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cardIcon,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    categoryName,
                    style: GoogleFonts.plusJakartaSans(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Game Title
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2For(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Metadata pills (Duration, Difficulty, Reward)
              Row(
                children: [
                  _buildMetaPill(context, Icons.timer_outlined, duration),
                  const SizedBox(width: 8),
                  _buildMetaPill(context, Icons.bar_chart_rounded, difficulty),
                  const SizedBox(width: 8),
                  _buildMetaPill(context, Icons.stars_rounded, reward,
                      isHighlight: true),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                height: 1,
                color: AppColors.borderFor(context).withValues(alpha: 0.4),
              ),
              const SizedBox(height: 18),

              // Full-width Join Now button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Join Now',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaPill(BuildContext context, IconData icon, String value,
      {bool isHighlight = false}) {
    final accentColor =
        isHighlight ? const Color(0xFFFF9F00) : AppColors.text3For(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFFFF9F00).withValues(alpha: 0.08)
            : AppColors.borderFor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFFF9F00).withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isHighlight
                  ? const Color(0xFFFF9F00)
                  : AppColors.text2For(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }


}

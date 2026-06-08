import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import 'duel_mode_landing_screen.dart';
import 'daily_challenge_screen.dart';

class ArenaDuelsSection extends StatefulWidget {
  const ArenaDuelsSection({super.key});

  @override
  State<ArenaDuelsSection> createState() => _ArenaDuelsSectionState();
}

class _ArenaDuelsSectionState extends State<ArenaDuelsSection> {
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'COMBAT',
      'icon': Icons.bolt_rounded,
      'color': Colors.amber,
      'score': '1013',
      'headline': 'Fast technical rounds',
      'description': 'Quick coding fundamentals, shortcuts, and dev trivia.',
      'reward': '+25 aura',
      'active': '18 live',
    },
    {
      'name': 'TEAM',
      'icon': Icons.forum_rounded,
      'color': Colors.green,
      'score': '920',
      'headline': 'Squad based scoring',
      'description': 'Pair up with builders and win points together.',
      'reward': '+40 team aura',
      'active': '6 squads',
    },
    {
      'name': 'DAILY CHALLENGE',
      'icon': Icons.emoji_events_rounded,
      'color': Colors.pinkAccent,
      'score': '750',
      'headline': 'One focused task',
      'description': 'Finish today\'s challenge to keep your streak moving.',
      'reward': 'streak boost',
      'active': 'today',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big Categories
        Container(
          height: 125,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_categories.length, (index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          height: 70,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat['color']
                                : AppColors.bg2For(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? cat['color']
                                  : AppColors.borderFor(context)
                                      .withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  cat['icon'],
                                  size: 26,
                                  color:
                                      isSelected ? Colors.black : cat['color'],
                                ).animate(target: isSelected ? 1 : 0).moveY(
                                      begin: 0,
                                      end: -6,
                                      duration: 250.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.8),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(14),
                                        bottomRight: Radius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      cat['score'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .slideY(
                                        begin: 1,
                                        end: 0,
                                        duration: 250.ms,
                                        curve: Curves.easeOut,
                                      )
                                      .fadeIn(duration: 250.ms),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? cat['color']
                                : AppColors.text3For(context),
                            letterSpacing: -0.2,
                          ),
                          child: Text(
                            cat['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Duels
        Builder(
          builder: (context) {
            final selectedCategory = _categories[_selectedCategory];
            final catName = selectedCategory['name'];
            final categoryColor = selectedCategory['color'] as Color;
            final isCombat = catName == 'COMBAT';
            final isSocial = catName == 'TEAM';
            final isDaily = catName == 'DAILY CHALLENGE';

            final title1 = isDaily
                ? 'DAILY\nMISSION'
                : isCombat
                    ? 'REFLEX\nMODE'
                    : isSocial
                        ? 'TEAM\nBATTLE'
                        : 'SPRINT\nDUELS';
            final mode1 = isCombat
                ? 'Reflex Mode'
                : isSocial
                    ? 'Team Battle'
                    : 'Sprint Duels';

            final title2 = isCombat ? 'CODE\nCOMBAT' : 'FAST & FIRST\nDUELS';
            final mode2 = isCombat ? 'Code Combat' : 'Fast & First Duels';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _CategorySummary(
                    color: categoryColor,
                    headline: selectedCategory['headline'],
                    description: selectedCategory['description'],
                    reward: selectedCategory['reward'],
                    active: selectedCategory['active'],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DuelCard(
                    categoryName: catName,
                    title: title1,
                    subtitle: isDaily
                        ? 'COMPLETE YOUR DAILY TECHNICAL CHALLENGE'
                        : isSocial
                            ? 'TEAM UP WITH FRIENDS AND COMPETE'
                            : 'RACE TO SOLVE THE MOST IN 1 MINUTE',
                    accentColor: categoryColor,
                    badgeText: isDaily
                        ? 'TODAY'
                        : isSocial
                            ? 'SQUAD'
                            : 'LIVE',
                    onTap: () {
                      if (isDaily) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DailyChallengeScreen(),
                        ));
                      } else {
                        _startMatchmaking(catName, mode1);
                      }
                    },
                  ),
                ),
                if (!isSocial && !isDaily) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DuelCard(
                      categoryName: catName,
                      title: title2,
                      subtitle: 'BE THE FIRST TO ANSWER EACH QUESTION',
                      accentColor: categoryColor,
                      badgeText: 'RANKED',
                      onTap: () => _startMatchmaking(catName, mode2),
                    ),
                  ),
                ],
              ],
            )
                .animate(key: ValueKey(_selectedCategory))
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ],
    );
  }

  void _startMatchmaking(String category, String mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelModeLandingScreen(
          category: category,
          mode: mode,
          color: _categories[_selectedCategory]['color'],
        ),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  final Color color;
  final String headline;
  final String description;
  final String reward;
  final String active;

  const _CategorySummary({
    required this.color,
    required this.headline,
    required this.description,
    required this.reward,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textFor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text3For(context),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(label: active, color: color),
              const SizedBox(height: 6),
              _MiniStat(label: reward, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DuelCard extends StatefulWidget {
  final String categoryName;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String badgeText;
  final VoidCallback onTap;

  const _DuelCard({
    required this.categoryName,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.badgeText,
    required this.onTap,
  });

  @override
  State<_DuelCard> createState() => _DuelCardState();
}

class _DuelCardState extends State<_DuelCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _setPressed(true);
      },
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.accentColor.withValues(
                  alpha: _pressed ? 0.42 : 0.22,
                ),
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: widget.accentColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: GoogleFonts.oswald(
                          fontSize: 36,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        widget.badgeText,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedScale(
                      scale: _pressed ? 0.9 : 1,
                      duration: const Duration(milliseconds: 90),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: widget.accentColor,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

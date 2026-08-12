import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/practice_questions.dart';
import '../providers/practice_provider.dart';
import '../theme/app_colors.dart';
import 'practice_question_screen.dart';

class PracticeMapScreen extends StatefulWidget {
  const PracticeMapScreen({super.key});

  @override
  State<PracticeMapScreen> createState() => _PracticeMapScreenState();
}

class _PracticeMapScreenState extends State<PracticeMapScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final practiceProvider = context.watch<PracticeProvider>();
    final currentSectionIndex = practiceProvider.selectedSectionIndex;
    final levelInfo = PracticeLevelData.levels[currentSectionIndex];
    final Color themeColor = Color(levelInfo['color'] as int);
    final String levelName = levelInfo['name'] as String;
    final questions = PracticeLevelData.getQuestionsForLevel(currentSectionIndex);
    final completedCount = practiceProvider.getCompletedCountForSection(currentSectionIndex);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            _buildHeader(context, practiceProvider, themeColor),

            // ── Section Selector Tabs (Noob, Easy, Medium, Hard) ─────────────
            _buildSectionTabs(context, practiceProvider),

            // ── Main Map Canvas ─────────────────────────────────────────────
            Expanded(
              child: practiceProvider.isLoading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Section Header Banner
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  themeColor.withValues(alpha: 0.25),
                                  themeColor.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: themeColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getLevelIcon(currentSectionIndex),
                                    color: themeColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SECTION ${currentSectionIndex + 1}: $levelName',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: themeColor,
                                          letterSpacing: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        levelInfo['tagline'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textFor(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Progress bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: questions.isNotEmpty
                                              ? completedCount / questions.length
                                              : 0,
                                          backgroundColor: AppColors.borderFor(context),
                                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  children: [
                                    Text(
                                      '$completedCount/20',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textFor(context),
                                      ),
                                    ),
                                    Text(
                                      'Solved',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text3For(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Candy Crush / Duolingo Level Path
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final q = questions[index];
                                final bool isUnlocked = practiceProvider
                                    .isQuestionUnlocked(q.levelIndex, q.questionNumber);
                                final bool isCompleted = practiceProvider
                                    .isQuestionCompleted(q.id);
                                final bool isNextUnlocked = index < questions.length - 1 &&
                                    practiceProvider.isQuestionUnlocked(
                                        questions[index + 1].levelIndex,
                                        questions[index + 1].questionNumber);

                                // Calculate horizontal curve offset for serpentine track
                                final double curveOffset = _getCurveOffset(index);

                                return _buildPathNodeRow(
                                  context: context,
                                  question: q,
                                  index: index,
                                  totalQuestions: questions.length,
                                  isUnlocked: isUnlocked,
                                  isCompleted: isCompleted,
                                  isNextUnlocked: isNextUnlocked,
                                  curveOffset: curveOffset,
                                  themeColor: themeColor,
                                );
                              },
                              childCount: questions.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER & SECTION SELECTOR TABS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
      BuildContext context, PracticeProvider practiceProvider, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textFor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Practice Mode',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'UNTIMED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00E676),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'No time bounds • Learn at your own pace',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3For(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Total Stats Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg2For(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFFD300),
                  size: 16,
                ),
                const SizedBox(width: 3),
                Text(
                  '+${practiceProvider.totalAuraEarned}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(
      BuildContext context, PracticeProvider practiceProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: List.generate(PracticeLevelData.levels.length, (index) {
          final level = PracticeLevelData.levels[index];
          final isSelected = practiceProvider.selectedSectionIndex == index;
          final isUnlocked = practiceProvider.isSectionUnlocked(index);
          final color = Color(level['color'] as int);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (isUnlocked) {
                practiceProvider.setSelectedSection(index);
              } else {
                _showSectionLockedDialog(context, level['name'] as String, index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : isUnlocked
                        ? AppColors.bg2For(context)
                        : AppColors.bg2For(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? color
                      : isUnlocked
                          ? AppColors.borderFor(context)
                          : AppColors.borderFor(context).withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    isUnlocked
                        ? _getLevelIcon(index)
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : isUnlocked
                            ? color
                            : AppColors.text3For(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    level['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? Colors.white
                          : isUnlocked
                              ? AppColors.textFor(context)
                              : AppColors.text3For(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.borderFor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '20 Qs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : AppColors.text2For(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DUOLINGO / CANDY CRUSH WINDING PATH NODE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPathNodeRow({
    required BuildContext context,
    required PracticeQuestion question,
    required int index,
    required int totalQuestions,
    required bool isUnlocked,
    required bool isCompleted,
    required bool isNextUnlocked,
    required double curveOffset,
    required Color themeColor,
  }) {
    final practiceProvider = context.read<PracticeProvider>();
    final bool isCurrentActive = isUnlocked &&
        (!isCompleted ||
            (index < totalQuestions - 1 &&
                !practiceProvider.isQuestionCompleted(
                    '${_getLevelPrefix(question.levelIndex)}_${question.questionNumber + 1}')));

    final bool isSpecialMilestone =
        question.questionNumber == 10 || question.questionNumber == 20;

    const double rowHeight = 115.0;
    const double circleCenterY = 36.0;

    final double screenWidth = MediaQuery.of(context).size.width - 40;
    final double maxOffset = math.min(screenWidth * 0.32, 110.0);

    return SizedBox(
      height: rowHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Connection Path Line to next node if not the last question
          if (index < totalQuestions - 1)
            Positioned(
              top: circleCenterY,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(screenWidth, rowHeight),
                painter: PathConnectorPainter(
                  startOffset: curveOffset,
                  endOffset: _getCurveOffset(index + 1),
                  isCompleted: isCompleted,
                  isNextUnlocked: isNextUnlocked,
                  themeColor: themeColor,
                ),
              ),
            ),

          // Level Node Button & Title
          Positioned(
            top: 0,
            child: Transform.translate(
              offset: Offset(curveOffset * maxOffset, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      if (isUnlocked) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PracticeQuestionScreen(
                              question: question,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Complete Question ${question.questionNumber - 1} to unlock this question!',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF1E1E24),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Active Glow Ring
                        if (isCurrentActive && !isCompleted)
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeColor.withValues(alpha: 0.2),
                              border: Border.all(
                                color: themeColor,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.08, 1.08),
                                duration: 900.ms,
                                curve: Curves.easeInOut,
                              ),

                        // Node Circle Base
                        Container(
                          width: isSpecialMilestone ? 74 : 68,
                          height: isSpecialMilestone ? 74 : 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isCompleted
                                  ? [
                                      const Color(0xFF00E676),
                                      const Color(0xFF00B0FF),
                                    ]
                                  : isUnlocked
                                      ? [
                                          themeColor,
                                          themeColor.withValues(alpha: 0.8),
                                        ]
                                      : [
                                          AppColors.bg2For(context),
                                          AppColors.bg2For(context),
                                        ],
                            ),
                            border: Border.all(
                              color: isCompleted
                                  ? Colors.white
                                  : isUnlocked
                                      ? themeColor
                                      : AppColors.borderFor(context),
                              width: isCompleted ? 3 : 2,
                            ),
                            boxShadow: isUnlocked
                                ? [
                                    BoxShadow(
                                      color: (isCompleted ? const Color(0xFF00E676) : themeColor)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  )
                                : isUnlocked
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (isSpecialMilestone)
                                            Icon(
                                              question.questionNumber == 20
                                                  ? Icons.emoji_events_rounded
                                                  : Icons.card_giftcard_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          Text(
                                            '${question.questionNumber}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize:
                                                  isSpecialMilestone ? 20 : 22,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.lock_rounded,
                                        color: AppColors.text3For(context),
                                        size: 24,
                                      ),
                          ),
                        ),

                        // "START" Floating Badge for current active level
                        if (isCurrentActive && !isCompleted)
                          Positioned(
                            top: -14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'START',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),

                        // Star Badge for Completed Levels
                        if (isCompleted)
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 11, color: Colors.black),
                                  Icon(Icons.star_rounded,
                                      size: 11, color: Colors.black),
                                  Icon(Icons.star_rounded,
                                      size: 11, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Question Label
                  Text(
                    'Q${question.questionNumber}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCompleted
                          ? const Color(0xFF00E676)
                          : isUnlocked
                              ? AppColors.textFor(context)
                              : AppColors.text3For(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS & PAINTERS
  // ══════════════════════════════════════════════════════════════════════════

  double _getCurveOffset(int index) {
    // S-curve pattern: smooth oscillation
    final double angle = (index * math.pi / 3.5);
    return math.sin(angle) * 0.65;
  }

  IconData _getLevelIcon(int levelIndex) {
    switch (levelIndex) {
      case 0:
        return Icons.eco_rounded;
      case 1:
        return Icons.speed_rounded;
      case 2:
        return Icons.psychology_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  String _getLevelPrefix(int levelIndex) {
    switch (levelIndex) {
      case 0:
        return 'noob';
      case 1:
        return 'easy';
      case 2:
        return 'med';
      case 3:
        return 'hard';
      default:
        return 'noob';
    }
  }

  void _showSectionLockedDialog(
      BuildContext context, String name, int levelIndex) {
    final prevLevelName = PracticeLevelData.levels[levelIndex - 1]['name'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFFF9F00)),
            const SizedBox(width: 8),
            Text(
              'Section Locked',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.textFor(context),
              ),
            ),
          ],
        ),
        content: Text(
          'Complete all 20 questions in $prevLevelName section to unlock $name section!',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.text2For(context),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class PathConnectorPainter extends CustomPainter {
  final double startOffset;
  final double endOffset;
  final bool isCompleted;
  final bool isNextUnlocked;
  final Color themeColor;

  PathConnectorPainter({
    required this.startOffset,
    required this.endOffset,
    required this.isCompleted,
    required this.isNextUnlocked,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double maxOffset = math.min(size.width * 0.32, 110.0);

    final double startX = centerX + (startOffset * maxOffset);
    final double startY = 0;
    final double endX = centerX + (endOffset * maxOffset);
    final double endY = size.height;

    final path = Path();
    path.moveTo(startX, startY);
    path.cubicTo(
      startX,
      startY + (size.height * 0.5),
      endX,
      endY - (size.height * 0.5),
      endX,
      endY,
    );

    // 1. Background dark track shadow
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bgPaint);

    // 2. Main path line
    final Color pathColor = isCompleted
        ? const Color(0xFF00E676)
        : isNextUnlocked
            ? themeColor
            : themeColor.withValues(alpha: 0.25);

    final linePaint = Paint()
      ..color = pathColor
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // 3. Glow overlay for completed segments
    if (isCompleted) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
        ..strokeWidth = 9.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PathConnectorPainter oldDelegate) {
    return oldDelegate.startOffset != startOffset ||
        oldDelegate.endOffset != endOffset ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isNextUnlocked != isNextUnlocked ||
        oldDelegate.themeColor != themeColor;
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/practice_questions.dart';
import '../providers/practice_provider.dart';
import '../theme/app_colors.dart';

class PracticeQuestionScreen extends StatefulWidget {
  final PracticeQuestion question;

  const PracticeQuestionScreen({
    super.key,
    required this.question,
  });

  @override
  State<PracticeQuestionScreen> createState() => _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState extends State<PracticeQuestionScreen> {
  int? _selectedOptionIndex;
  bool _hasSubmitted = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final practiceProvider = context.watch<PracticeProvider>();
    final levelInfo = PracticeLevelData.levels[widget.question.levelIndex];
    final Color themeColor = Color(levelInfo['color'] as int);
    final auraReward = levelInfo['auraPerQuestion'] as int;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Bar ──────────────────────────────────────────────────
            _buildTopBar(context, themeColor),

            // ── Progress Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: widget.question.questionNumber / 20.0,
                  backgroundColor: AppColors.borderFor(context),
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: 6,
                ),
              ),
            ),

            // ── Main Content Area ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Tag & Untimed Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: themeColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${widget.question.levelName.toUpperCase()} • Q${widget.question.questionNumber}/20',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: themeColor,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD300).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFD300).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: Color(0xFFFFD300), size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '+$auraReward Aura',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFD300),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Question Text
                    Text(
                      widget.question.question,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                        height: 1.4,
                      ),
                    ),

                    // Code Snippet Box (if available)
                    if (widget.question.codeSnippet != null &&
                        widget.question.codeSnippet!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A2A32),
                          ),
                        ),
                        child: Text(
                          widget.question.codeSnippet!,
                          style: GoogleFonts.firaCode(
                            fontSize: 13,
                            color: const Color(0xFFE2E8F0),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Options List
                    Text(
                      'Select one correct answer:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3For(context),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...List.generate(widget.question.options.length, (index) {
                      final optionText = widget.question.options[index];
                      final isSelected = _selectedOptionIndex == index;
                      final isCorrectOption =
                          index == widget.question.correctIndex;

                      Color optionBorderColor = AppColors.borderFor(context);
                      Color optionBgColor = AppColors.bg2For(context);
                      Color textColor = AppColors.textFor(context);

                      if (_hasSubmitted) {
                        if (isCorrectOption) {
                          optionBorderColor = const Color(0xFF00E676);
                          optionBgColor =
                              const Color(0xFF00E676).withValues(alpha: 0.12);
                          textColor = const Color(0xFF00E676);
                        } else if (isSelected && !isCorrectOption) {
                          optionBorderColor = const Color(0xFFFF1744);
                          optionBgColor =
                              const Color(0xFFFF1744).withValues(alpha: 0.12);
                          textColor = const Color(0xFFFF1744);
                        }
                      } else if (isSelected) {
                        optionBorderColor = themeColor;
                        optionBgColor = themeColor.withValues(alpha: 0.1);
                      }

                      return GestureDetector(
                        onTap: () {
                          if (_hasSubmitted && _isCorrect) return;
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedOptionIndex = index;
                            _hasSubmitted = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: optionBgColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: optionBorderColor,
                              width: isSelected || (_hasSubmitted && isCorrectOption)
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? optionBorderColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? optionBorderColor
                                        : AppColors.borderFor(context),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isSelected
                                      ? Icon(
                                          _hasSubmitted
                                              ? (isCorrectOption
                                                  ? Icons.check
                                                  : Icons.close)
                                              : Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : Text(
                                          String.fromCharCode(65 + index),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text3For(context),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Explanation Card (Shown after submitting)
                    if (_hasSubmitted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? const Color(0xFF00E676).withValues(alpha: 0.08)
                              : const Color(0xFFFF1744).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isCorrect
                                ? const Color(0xFF00E676).withValues(alpha: 0.3)
                                : const Color(0xFFFF1744).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  color: _isCorrect
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFF1744),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCorrect
                                      ? 'Correct! Excellent job!'
                                      : 'Not quite right. Try again!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: _isCorrect
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF1744),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.question.explanation,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.text2For(context),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom Action Button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedOptionIndex == null
                      ? null
                      : () => _handleSubmit(context, practiceProvider, themeColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSubmitted && _isCorrect
                        ? const Color(0xFF00E676)
                        : themeColor,
                    disabledBackgroundColor:
                        AppColors.borderFor(context).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _hasSubmitted
                        ? (_isCorrect ? 'Continue Next Question' : 'Try Again')
                        : 'Check Answer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textFor(context),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 4),
              Text(
                'Untimed Mode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text2For(context),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showHintSheet(context, themeColor),
            icon: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFFFFD300),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(
      BuildContext context, PracticeProvider practiceProvider, Color themeColor) async {
    if (_selectedOptionIndex == null) return;

    // If already correctly answered and user taps "Continue Next Question":
    if (_hasSubmitted && _isCorrect) {
      _navigateToNextQuestion(context, practiceProvider);
      return;
    }

    final bool correct =
        _selectedOptionIndex == widget.question.correctIndex;

    setState(() {
      _hasSubmitted = true;
      _isCorrect = correct;
    });

    if (correct) {
      HapticFeedback.heavyImpact();
      await practiceProvider.completeQuestion(widget.question.id);

      if (!mounted) return;

      // Check if it's question 20 (completion of section!)
      if (widget.question.questionNumber == 20) {
        // ignore: use_build_context_synchronously
        _showSectionCompletionModal(context, themeColor);
      }
    } else {
      HapticFeedback.vibrate();
    }
  }

  void _navigateToNextQuestion(
      BuildContext context, PracticeProvider practiceProvider) {
    if (widget.question.questionNumber < 20) {
      final questions = PracticeLevelData.getQuestionsForLevel(widget.question.levelIndex);
      final nextQuestion = questions[widget.question.questionNumber]; // index = questionNumber

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeQuestionScreen(question: nextQuestion),
        ),
      );
    } else {
      // Completed Q20, return to level map
      Navigator.pop(context);
    }
  }

  void _showHintSheet(BuildContext context, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2For(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD300), size: 24),
                const SizedBox(width: 10),
                Text(
                  'Question Hint',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.question.hint,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.text2For(context),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Got it!', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSectionCompletionModal(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_rounded, size: 48, color: themeColor),
            ),
            const SizedBox(height: 16),
            Text(
              'SECTION COMPLETED!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: themeColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Awesome job! You solved all 20 questions in ${widget.question.levelName} section and unlocked the next level section!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.text2For(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Return to level map
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

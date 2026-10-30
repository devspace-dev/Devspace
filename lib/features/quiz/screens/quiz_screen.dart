import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/glitch.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/segment_bar.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../data/practice_questions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/practice_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../widgets/quiz_option_row.dart';

class QuizScreen extends StatefulWidget {
  final String lobby;
  const QuizScreen({super.key, required this.lobby});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final ConfettiController _confettiController;
  late final List<PracticeQuestion> _questions;

  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _gotWrong = false;
  int _sessionAuraEarned = 0;
  bool _roundCompleted = false;

  int get _levelIndex => switch (widget.lobby.toLowerCase()) {
        'noob' => 0,
        'scrims' => 1,
        'ranked' => 2,
        'final_circle' || 'final' => 3,
        _ => 0,
      };

  (String, String, Color) get _lobbyMeta => switch (_levelIndex) {
        0 => ('NOOB LOBBY', 'EASY', Ds.tierBronze),
        1 => ('SCRIMS', 'MEDIUM', Ds.tierSilver),
        2 => ('RANKED', 'HARD', Ds.tierGold),
        3 => ('FINAL CIRCLE', 'ULTRA', Ds.tierGem),
        _ => ('LOBBY', 'EASY', Ds.tierBronze),
      };

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 700));

    final allForLevel = practiceQuestionsData.where((q) => q.levelIndex == _levelIndex).toList();
    if (allForLevel.isEmpty) {
      _questions = practiceQuestionsData.take(8).toList();
    } else {
      _questions = allForLevel.take(8).toList();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int index) async {
    if (_answered) return;

    final q = _questions[_currentIndex];
    final isCorrect = index == q.correctIndex;
    final practiceP = context.read<PracticeProvider>();
    final authP = context.read<AuthProvider>();
    EngagementProvider? engagementP;
    try {
      engagementP = context.read<EngagementProvider>();
    } catch (_) {
      // Optional in unit/widget test environments
    }

    setState(() {
      _selectedIndex = index;
      _answered = true;
    });

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (isCorrect) {
      final reward = practiceP.getAuraForQuestion(q.id);
      if (!_gotWrong) {
        _sessionAuraEarned += reward;
        await practiceP.completeQuestion(
          q.id,
          authProvider: authP,
          engagementProvider: engagementP,
          awardAura: true,
        );
      } else {
        await practiceP.completeQuestion(
          q.id,
          authProvider: authP,
          engagementProvider: engagementP,
          awardAura: false,
        );
      }

      if (mounted && !disableAnimations) {
        _confettiController.play();
      }
      HapticFeedback.mediumImpact();
      // ignore: deprecated_member_use
      SemanticsService.announce('Correct answer. Big brain. +$reward Aura', TextDirection.ltr);
    } else {
      _gotWrong = true;
      HapticFeedback.heavyImpact();
      // ignore: deprecated_member_use
      SemanticsService.announce('Incorrect answer. Glitched.', TextDirection.ltr);
    }
  }

  void _onContinue() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
        _gotWrong = false;
      });
    } else {
      setState(() {
        _roundCompleted = true;
      });
      if (!MediaQuery.disableAnimationsOf(context)) {
        _confettiController.play();
      }
    }
  }

  Future<void> _handleClose() async {
    if (_roundCompleted || _currentIndex == 0 && !_answered) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/play');
      }
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Ds.surface,
        title: Text('QUIT QUIZ?', style: DsText.h3),
        content: Text(
          'Your progress in this session will be lost.',
          style: DsText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('STAY', style: DsText.button.copyWith(color: Ds.mint)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('QUIT', style: DsText.button.copyWith(color: Ds.hot)),
          ),
        ],
      ),
    );

    if (leave == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/play');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (lobbyTitle, levelName, tierColor) = _lobbyMeta;
    final totalAura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Scaffold(
        backgroundColor: Ds.ink,
        appBar: AppBar(
          backgroundColor: Ds.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Ds.bone, size: 28),
            tooltip: 'Close quiz',
            onPressed: _handleClose,
          ),
          title: SegmentBar(
            total: _questions.length,
            current: _roundCompleted ? _questions.length : _currentIndex + (_answered ? 1 : 0),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AuraChip(totalAura),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Confetti Cannon
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Ds.aura, Ds.mint, Ds.hot, Ds.bone],
                numberOfParticles: 25,
                gravity: 0.3,
              ),
            ),

            if (_roundCompleted)
              _buildRoundCompleteView(lobbyTitle, tierColor)
            else
              _buildQuizQuestionView(lobbyTitle, levelName, tierColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizQuestionView(String lobbyTitle, String levelName, Color tierColor) {
    final q = _questions[_currentIndex];
    final isCorrect = _answered && _selectedIndex == q.correctIndex;
    final practiceP = context.read<PracticeProvider>();
    final questionReward = practiceP.getAuraForQuestion(q.id);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row of Slanted Tags
                  Row(
                    children: [
                      DsTag('Q${_currentIndex + 1} OF ${_questions.length}'),
                      const SizedBox(width: 8),
                      DsTag(levelName, bg: tierColor, fg: Ds.ink),
                      const SizedBox(width: 8),
                      DsTag(q.techStack),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Text in Rubik 24 w700
                  Text(q.question, style: DsText.question),
                  const SizedBox(height: 16),

                  // Optional Code Snippet
                  if (q.codeSnippet != null && q.codeSnippet!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Ds.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Ds.border),
                      ),
                      child: Text(
                        q.codeSnippet!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Ds.aura,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Option Rows
                  ...List.generate(q.options.length, (index) {
                    final letter = String.fromCharCode(65 + index);
                    final optionText = q.options[index];

                    OptionState state = OptionState.idle;
                    if (_answered) {
                      if (index == q.correctIndex) {
                        state = OptionState.correct;
                      } else if (index == _selectedIndex) {
                        state = OptionState.wrong;
                      }
                    } else if (_selectedIndex == index) {
                      state = OptionState.selected;
                    }

                    return QuizOptionRow(
                      letter: letter,
                      text: optionText,
                      state: state,
                      onTap: _answered ? null : () => _onOptionSelected(index),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Pinned Bottom Feedback Panel (Never below the fold)
          if (_answered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isCorrect ? Ds.mintPanel : const Color(0xFF2B1418),
                border: Border(
                  top: BorderSide(
                    color: isCorrect ? Ds.mint : Ds.hot,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Glitch(
                        size: 56,
                        mood: isCorrect ? GlitchMood.win : GlitchMood.lose,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCorrect
                                  ? (_gotWrong
                                      ? 'CORRECT. +0 AURA'
                                      : 'BIG BRAIN. +$questionReward AURA')
                                  : 'GLITCHED.',
                              style: DsText.h3.copyWith(
                                color: isCorrect ? Ds.mint : Ds.hot,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              q.explanation,
                              style: DsText.bodySm.copyWith(color: Ds.bone),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DsButton(
                    label: _currentIndex == _questions.length - 1 ? 'FINISH ROUND' : 'CONTINUE',
                    kind: isCorrect ? DsButtonKind.mint : DsButtonKind.bone,
                    onPressed: _onContinue,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundCompleteView(String lobbyTitle, Color tierColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Glitch(size: 110, mood: GlitchMood.win),
            const SizedBox(height: 20),
            Text('ROUND CLEARED!', style: DsText.h1),
            const SizedBox(height: 8),
            Text(lobbyTitle, style: DsText.caption.copyWith(color: tierColor)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Ds.aura, width: 2),
              ),
              child: Column(
                children: [
                  Text('AURA EARNED', style: DsText.caption),
                  const SizedBox(height: 4),
                  Text('+$_sessionAuraEarned', style: DsText.display.copyWith(color: Ds.aura)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            DsButton(
              label: 'BACK TO ARENA',
              kind: DsButtonKind.aura,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/play');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

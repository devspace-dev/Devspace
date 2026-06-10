import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'duel_result_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

import '../data/duel_questions.dart';

class DuelScreen extends StatefulWidget {
  final String category;
  final String mode;
  final UserModel opponent;
  final String matchId;
  final bool isPlayer1;

  const DuelScreen({
    super.key,
    required this.category,
    required this.mode,
    required this.opponent,
    required this.matchId,
    required this.isPlayer1,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

enum DuelPhase { countdown, playing, finished }

class _DuelScreenState extends State<DuelScreen> {
  DuelPhase _phase = DuelPhase.countdown;
  int _countdown = 3;
  late int _timeRemaining;
  Timer? _timer;
  RealtimeChannel? _matchSubscription;

  int _myScore = 0;
  int _opponentScore = 0;
  int _questionsAnswered = 0;

  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  int _currentQuestionIndex = 0;

  final List<DuelQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    final modeUpper = widget.mode.toUpperCase();
    if (modeUpper == 'TEAM DUELS' || modeUpper == 'TEAM BATTLE') {
      _timeRemaining = 120;
    } else if (modeUpper == 'REFLEX MODE' || modeUpper == 'REFLEX') {
      _timeRemaining = 60;
    } else {
      _timeRemaining = 45;
    }

    if (modeUpper == 'REFLEX MODE' || modeUpper == 'REFLEX' || modeUpper == 'TEAM DUELS' || modeUpper == 'TEAM BATTLE') {
      _questions.addAll(reflexQuestions.toList()..shuffle());
    } else if (modeUpper == 'LOGIC LAB') {
      _questions.addAll(logicQuestions.toList()..shuffle());
    } else if (modeUpper == 'MIND GAMES') {
      _questions.addAll(triviaQuestions.toList()..shuffle());
    } else {
      // Fallback for any other modes
      _questions.addAll(reflexQuestions.toList()..shuffle());
    }

    _matchSubscription = Supabase.instance.client
        .channel('public:arena_matches:id=eq.${widget.matchId}')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'arena_matches',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: widget.matchId,
            ),
            callback: (payload) {
              if (mounted) {
                final record = payload.newRecord;
                setState(() {
                  _opponentScore = widget.isPlayer1
                      ? (record['player2_score'] as num?)?.toInt() ??
                          _opponentScore
                      : (record['player1_score'] as num?)?.toInt() ??
                          _opponentScore;
                });
              }
            })
        .subscribe();

    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _matchSubscription?.unsubscribe();
    _answerController.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {
          _phase = DuelPhase.playing;
        });
        _startGameTimer();
        if (_questions[_currentQuestionIndex].type == 'input') {
          _answerFocus.requestFocus();
        }
      }
    });
  }

  void _startGameTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
          // Simulate teammates scoring for Team Battle / Team Duels
          final modeUpper = widget.mode.toUpperCase();
          if ((modeUpper == 'TEAM BATTLE' || modeUpper == 'TEAM DUELS') &&
              _timeRemaining % 5 == 0 &&
              _timeRemaining != (modeUpper == 'TEAM DUELS' ? 120 : 60)) {
            _myScore += 15;
            SupabaseService.instance
                .updateArenaScore(widget.matchId, widget.isPlayer1, _myScore);
          }
        });
      } else {
        _endDuel();
      }
    });
  }

  void _endDuel() {
    _timer?.cancel();
    setState(() => _phase = DuelPhase.finished);

    if (widget.isPlayer1) {
      SupabaseService.instance.finishArenaMatch(widget.matchId);
    }

    _showGameOver();
  }

  void _showGameOver() {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null) return;

    final myCorrect = _myScore ~/ 15;
    final myAccuracy =
        _questionsAnswered > 0 ? (myCorrect / _questionsAnswered) * 100 : 0.0;

    // Opponent dummy stats
    final oppCorrect = _opponentScore ~/ 15;
    final oppQuestionsAnswered = oppCorrect > 0 ? oppCorrect + 1 : 0;
    final oppAccuracy = oppQuestionsAnswered > 0
        ? (oppCorrect / oppQuestionsAnswered) * 100
        : 0.0;

    final bool iWon = _myScore >= _opponentScore;
    int baseAura = iWon ? 15 : -5;
    int accuracyBonus = myAccuracy > 80 ? 10 : 0;
    int speedPenalty = iWon ? 0 : -5;
    int netAura = baseAura + accuracyBonus + speedPenalty;

    if (netAura > 0) {
      Supabase.instance.client.rpc('award_aura', params: {
        'p_user_id': me.id,
        'p_action': 'arena_duel',
        'p_points': netAura,
        'p_reference_type': 'arena',
        'p_reference_id': widget.matchId,
        'p_metadata': {'mode': widget.mode, 'score': _myScore, 'won': iWon}
      }).catchError((_) {}); // Fire and forget
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DuelResultScreen(
          me: me,
          opponent: widget.opponent,
          myScore: _myScore,
          opponentScore: _opponentScore,
          mode: widget.mode,
          myQuestionsAnswered: _questionsAnswered,
          opponentQuestionsAnswered: oppQuestionsAnswered,
          myAccuracy: myAccuracy,
          opponentAccuracy: oppAccuracy,
        ),
      ),
    );
  }

  void _submitAnswer([String? answer]) {
    if (_phase != DuelPhase.playing) return;

    final currentQ = _questions[_currentQuestionIndex];
    final submitted = answer ?? _answerController.text;

    if (submitted.trim().isEmpty) return;

    if (submitted.trim().toLowerCase() == currentQ.answer.toLowerCase()) {
      setState(() {
        _myScore += 15;
      });
      SupabaseService.instance
          .updateArenaScore(widget.matchId, widget.isPlayer1, _myScore);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correct! +15 points'),
          backgroundColor: Colors.green,
          duration: Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 400),
        ),
      );
    }

    _answerController.clear();
    _questionsAnswered++;

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      if (_questions[_currentQuestionIndex].type == 'input') {
        _answerFocus.requestFocus();
      } else {
        _answerFocus.unfocus();
      }
    } else {
      final modeUpper = widget.mode.toUpperCase();
      if (modeUpper == 'REFLEX MODE' || modeUpper == 'REFLEX' || modeUpper == 'TEAM BATTLE' || modeUpper == 'TEAM DUELS') {
        setState(() {
          _currentQuestionIndex = 0;
          _questions.shuffle();
        });
        if (_questions[_currentQuestionIndex].type == 'input') {
          _answerFocus.requestFocus();
        } else {
          _answerFocus.unfocus();
        }
      } else {
        _endDuel();
      }
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Players
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Me
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.greenAccent, width: 2),
                        ),
                        child: UserAvatar(user: me, size: 44),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                ? 'Your Team (4)'
                                : 'You',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${me.aura}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Opponent
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                ? 'Enemy Team (4)'
                                : widget.opponent.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.opponent.aura}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.pinkAccent, width: 2),
                        ),
                        child: UserAvatar(user: widget.opponent, size: 44),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Header: Scores and Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScoreBox(score: _myScore),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded,
                            color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(_timeRemaining),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScoreBox(score: _opponentScore),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Center(
                child: _phase == DuelPhase.countdown
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Starting in ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$_countdown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      )
                    : _buildCurrentQuestion(),
              ),
            ),

            // Bottom Input Area
            if (_phase == DuelPhase.playing &&
                _currentQuestionIndex < _questions.length &&
                _questions[_currentQuestionIndex].type == 'input')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    Text(
                      'TYPE OUT YOUR ANSWER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _answerController,
                        focusNode: _answerFocus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter answer',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onSubmitted: (_) => _submitAnswer(),
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

  Widget _buildCurrentQuestion() {
    if (_phase == DuelPhase.finished) {
      return const Text('Duel Finished!',
          style: TextStyle(color: Colors.white, fontSize: 24));
    }

    final currentQ = _questions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question count indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (widget.mode.toUpperCase() == 'REFLEX MODE' || widget.mode.toUpperCase() == 'REFLEX' || widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                  ? 'Question ${_questionsAnswered + 1}'
                  : 'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            currentQ.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          if (currentQ.codeSnippet != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                currentQ.codeSnippet!,
                style: GoogleFonts.firaCode(
                  fontSize: 15,
                  color: Colors.greenAccent,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (currentQ.type == 'mcq') ...[
            const SizedBox(height: 32),
            ...currentQ.options!.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _submitAnswer(opt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        opt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;

  const _ScoreBox({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
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
  Timer? _scoreSyncTimer;
  RealtimeChannel? _matchSubscription;

  UserModel? _teammate;
  UserModel? _opponentTeammate;

  int _myScore = 0;
  int _opponentScore = 0;
  int _myOwnAnswersScore = 0;
  int _myTeammateScore = 0;
  int _opponentPlayerScore = 0;
  int _opponentTeammateScore = 0;

  int _questionsAnswered = 0;
  final List<int> _myScoreTimeline = [0];
  final List<int> _opponentScoreTimeline = [0];
  final List<String> _activityFeed = [];

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
      _questions.addAll(reflexQuestions.toList()..shuffle());
    }

    _initializeTeammates().then((_) {
      if (mounted) {
        _startCountdown();
      }
    });

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
                final newOppScore = widget.isPlayer1
                    ? (record['player2_score'] as num?)?.toInt() ?? _opponentScore
                    : (record['player1_score'] as num?)?.toInt() ?? _opponentScore;

                if (newOppScore > _opponentScore) {
                  final diff = newOppScore - _opponentScore;
                  final steps = diff ~/ 15;
                  for (int i = 0; i < steps; i++) {
                    _opponentPlayerScore += 15;
                    _showStatusMessage('${widget.opponent.name} scored! +15');
                  }
                  setState(() {
                    _opponentScore = newOppScore;
                  });
                }
              }
            })
        .subscribe();
  }

  Future<void> _initializeTeammates() async {
    final modeUpper = widget.mode.toUpperCase();
    if (modeUpper == 'TEAM DUELS' || modeUpper == 'TEAM BATTLE') {
      try {
        final usersProvider = context.read<UsersProvider>();
        final me = context.read<AuthProvider>().currentUserOrNull;

        List<UserModel> otherUsers = usersProvider.users
            .where((u) => u.id != me?.id && u.id != widget.opponent.id)
            .toList();

        if (otherUsers.length < 2) {
          final dbUsers = await SupabaseService.instance.getUsers(limit: 50);
          otherUsers = dbUsers
              .where((u) => u.id != me?.id && u.id != widget.opponent.id)
              .toList();
        }

        if (otherUsers.isNotEmpty) {
          otherUsers.shuffle();
          setState(() {
            _teammate = otherUsers[0];
            if (otherUsers.length > 1) {
              _opponentTeammate = otherUsers[1];
            }
          });
        }
      } catch (_) {}

      _teammate ??= UserModel(
        id: 'fallback_teammate_1',
        name: 'Aravind',
        handle: 'aravind_dev',
        email: 'aravind@devspace.com',
        avatar: '',
        color: Colors.tealAccent,
        aura: 1250,
        roles: const ['Frontend Lead'],
        year: '3rd Year',
        branch: 'CSE',
        building: 'Tech Block',
        stack: const ['Flutter', 'React'],
        followers: 45,
        following: 32,
        bio: 'Flutter enthusiast & student builder.',
        college: 'CBIT',
        githubHandle: 'aravinddev',
        profileCompleted: true,
      );

      _opponentTeammate ??= UserModel(
        id: 'fallback_teammate_2',
        name: 'Neha',
        handle: 'neha_builds',
        email: 'neha@devspace.com',
        avatar: '',
        color: Colors.amberAccent,
        aura: 1180,
        roles: const ['UI/UX Designer'],
        year: '2nd Year',
        branch: 'IT',
        building: 'Design Hub',
        stack: const ['Figma', 'CSS'],
        followers: 68,
        following: 54,
        bio: 'Designing the future of dev communities.',
        college: 'CBIT',
        githubHandle: 'nehabuilds',
        profileCompleted: true,
      );
    }
  }

  void _showStatusMessage(String msg) {
    if (!mounted) return;
    setState(() {
      _activityFeed.insert(0, msg);
      if (_activityFeed.length > 3) {
        _activityFeed.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scoreSyncTimer?.cancel();
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
        _startScoreSync();
        if (_questions[_currentQuestionIndex].type == 'input') {
          _answerFocus.requestFocus();
        }
      }
    });
  }

  void _startScoreSync() {
    _scoreSyncTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _phase != DuelPhase.playing) {
        timer.cancel();
        return;
      }
      try {
        final matchData = await Supabase.instance.client
            .from('arena_matches')
            .select('player1_score, player2_score')
            .eq('id', widget.matchId)
            .maybeSingle();
        if (matchData != null && mounted && _phase == DuelPhase.playing) {
          final newOppScore = widget.isPlayer1
              ? (matchData['player2_score'] as num?)?.toInt() ?? _opponentScore
              : (matchData['player1_score'] as num?)?.toInt() ?? _opponentScore;
          if (newOppScore > _opponentScore) {
            final diff = newOppScore - _opponentScore;
            final steps = diff ~/ 15;
            for (int i = 0; i < steps; i++) {
              _opponentPlayerScore += 15;
              _showStatusMessage('${widget.opponent.name} scored! +15');
            }
            setState(() {
              _opponentScore = newOppScore;
            });
          }
        }
      } catch (e) {
        debugPrint('Error syncing score: $e');
      }
    });
  }

  void _startGameTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
          
          final isMockOpponent = widget.opponent.id == 'solo' || widget.opponent.handle == 'challenger';
          if (isMockOpponent) {
            if (_timeRemaining % 8 == 0 && _timeRemaining > 0) {
              if (DateTime.now().millisecond % 10 < 6) {
                _opponentPlayerScore += 15;
                _opponentScore = _opponentPlayerScore + _opponentTeammateScore;
                SupabaseService.instance
                    .updateArenaScore(widget.matchId, !widget.isPlayer1, _opponentScore);
                _showStatusMessage('${widget.opponent.name} scored! +15');
              }
            }
          }
        });
        _myScoreTimeline.add(_myScore);
        _opponentScoreTimeline.add(_opponentScore);
      } else {
        _endDuel();
      }
    });
  }

  void _endDuel() async {
    _timer?.cancel();
    _scoreSyncTimer?.cancel();
    setState(() => _phase = DuelPhase.finished);

    if (widget.isPlayer1) {
      try {
        await SupabaseService.instance.finishArenaMatch(widget.matchId);
      } catch (_) {}
    }

    try {
      final matchData = await Supabase.instance.client
          .from('arena_matches')
          .select('player1_score, player2_score')
          .eq('id', widget.matchId)
          .maybeSingle();
      if (matchData != null) {
        final finalOppScore = widget.isPlayer1
            ? (matchData['player2_score'] as num?)?.toInt() ?? _opponentScore
            : (matchData['player1_score'] as num?)?.toInt() ?? _opponentScore;
        final finalMyScore = widget.isPlayer1
            ? (matchData['player1_score'] as num?)?.toInt() ?? _myScore
            : (matchData['player2_score'] as num?)?.toInt() ?? _myScore;
        
        setState(() {
          _opponentScore = finalOppScore;
          _myScore = finalMyScore;
          if (_myScoreTimeline.isNotEmpty) {
            _myScoreTimeline[_myScoreTimeline.length - 1] = _myScore;
          }
          if (_opponentScoreTimeline.isNotEmpty) {
            _opponentScoreTimeline[_opponentScoreTimeline.length - 1] = _opponentScore;
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting final score: $e');
    }

    _showGameOver();
  }

  void _showGameOver() {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null) return;

    final myCorrect = _myOwnAnswersScore ~/ 15;
    final myAccuracy =
        _questionsAnswered > 0 ? (myCorrect / _questionsAnswered) * 100 : 0.0;

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
      }).catchError((_) {});

      if ((widget.mode.toUpperCase() == 'TEAM DUELS' || widget.mode.toUpperCase() == 'TEAM BATTLE') &&
          _teammate != null &&
          !_teammate!.id.startsWith('fallback_')) {
        Supabase.instance.client.rpc('award_aura', params: {
          'p_user_id': _teammate!.id,
          'p_action': 'arena_duel',
          'p_points': netAura,
          'p_reference_type': 'arena',
          'p_reference_id': widget.matchId,
          'p_metadata': {'mode': widget.mode, 'score': _myScore, 'won': iWon, 'role': 'teammate'}
        }).catchError((_) {});
      }
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
          myScoreTimeline: _myScoreTimeline,
          opponentScoreTimeline: _opponentScoreTimeline,
          teammate: _teammate,
          opponentTeammate: _opponentTeammate,
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
        _myOwnAnswersScore += 15;
        _myScore = _myOwnAnswersScore + _myTeammateScore;
      });
      SupabaseService.instance
          .updateArenaScore(widget.matchId, widget.isPlayer1, _myScore);
      _showStatusMessage('You answered correctly! +15');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Correct! +15 points'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 160,
            left: 20,
            right: 20,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 160,
            left: 20,
            right: 20,
          ),
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

  Widget _buildTeamAvatars(UserModel user1, UserModel? user2, {required bool isLeft}) {
    if (user2 == null) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isLeft ? Colors.greenAccent : Colors.pinkAccent, width: 2),
        ),
        child: UserAvatar(user: user1, size: 44),
      );
    }

    return SizedBox(
      width: 72,
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: isLeft ? 0 : 24,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141414),
                border: Border.all(color: isLeft ? Colors.greenAccent : Colors.pinkAccent, width: 2),
              ),
              child: UserAvatar(user: user1, size: 38),
            ),
          ),
          Positioned(
            left: isLeft ? 24 : 0,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141414),
                border: Border.all(color: isLeft ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.pinkAccent.withValues(alpha: 0.7), width: 2),
              ),
              child: UserAvatar(user: user2, size: 38),
            ),
          ),
        ],
      ),
    );
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
                children: [
                  // Me
                  Expanded(
                    child: Row(
                      children: [
                        _buildTeamAvatars(me, _teammate, isLeft: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                    ? 'You & ${_teammate?.name.split(" ").first ?? "Teammate"}'
                                    : 'You',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                    ? '${me.aura + (_teammate?.aura ?? 0)} Aura'
                                    : '${me.aura} Aura',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Opponent
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                    ? '${widget.opponent.name.split(" ").first} & ${_opponentTeammate?.name.split(" ").first ?? "Teammate"}'
                                    : widget.opponent.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS')
                                    ? '${widget.opponent.aura + (_opponentTeammate?.aura ?? 0)} Aura'
                                    : '${widget.opponent.aura} Aura',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildTeamAvatars(widget.opponent, _opponentTeammate, isLeft: false),
                      ],
                    ),
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

            // Activity Feed
            if (_phase == DuelPhase.playing && _activityFeed.isNotEmpty && 
                (widget.mode.toUpperCase() == 'TEAM BATTLE' || widget.mode.toUpperCase() == 'TEAM DUELS'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _activityFeed.map((msg) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            msg.contains('correctly') || msg.contains('scored')
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            color: Colors.greenAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
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
              style: const TextStyle(
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

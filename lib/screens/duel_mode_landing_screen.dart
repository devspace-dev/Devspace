import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_model.dart';
import 'matchmaking_screen.dart';
import 'play_a_friend_screen.dart';
import 'duel_screen.dart';

class DuelModeLandingScreen extends StatelessWidget {
  final String category;
  final String mode;
  final Color color;

  const DuelModeLandingScreen({
    super.key,
    required this.category,
    required this.mode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PressableScale(
                    haptic: HapticFeedback.lightImpact,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'HOW TO PLAY?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Tags
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '1 MIN DUEL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Big Title
              Text(
                mode.toUpperCase().replaceAll(' ', '\n'),
                style: GoogleFonts.oswald(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: 1.5,
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(),

              const SizedBox(height: 24),

              // Subtitle
              Text(
                _getSubtitle(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Start Duel Button
              _PressableScale(
                haptic: HapticFeedback.mediumImpact,
                onTap: () {
                  if (mode == 'Logic Lab' || mode == 'Mind Games') {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DuelScreen(
                          category: category,
                          mode: mode,
                          matchId: 'solo',
                          isPlayer1: true,
                          opponent: UserModel(
                            id: 'solo',
                            name: 'Par Score',
                            handle: 'system',
                            email: '',
                            avatar: '',
                            color: Colors.blueGrey,
                            aura: 1000,
                            roles: [],
                            year: '',
                            branch: '',
                            building: '',
                            stack: [],
                            followers: 0,
                            following: 0,
                            bio: '',
                            college: '',
                            githubHandle: '',
                            profileCompleted: true,
                          ),
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MatchmakingScreen(
                          category: category,
                          mode: mode,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getButtonText(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    delay: 300.ms,
                  )
                  .fadeIn(),

              if (mode != 'Logic Lab' && mode != 'Mind Games') ...[
                const SizedBox(height: 24),
                // Play a friend button
                Center(
                  child: _PressableScale(
                    haptic: HapticFeedback.lightImpact,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayAFriendScreen(
                            category: category,
                            mode: mode,
                            color: color,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'PLAY A FRIEND',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (mode.toUpperCase()) {
      case 'REFLEX MODE':
        return 'RACE TO SOLVE THE MOST IN 60 SECONDS';
      case 'TEAM DUELS':
      case 'TEAM BATTLE':
        return 'TEAM UP AND SCORE POINTS TOGETHER (2 MINS)';
      case 'LOGIC LAB':
      case 'MIND GAMES':
        return 'TEST YOUR LOGIC AGAINST THE PAR SCORE';
      default:
        return 'RACE TO SOLVE THE MOST IN 45 SECONDS';
    }
  }

  String _getButtonText() {
    switch (mode.toUpperCase()) {
      case 'LOGIC LAB':
      case 'MIND GAMES':
        return 'START CHALLENGE';
      case 'TEAM DUELS':
      case 'TEAM BATTLE':
        return 'FIND TEAMMATES';
      default:
        return 'START DUEL';
    }
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback haptic;

  const _PressableScale({
    required this.child,
    required this.onTap,
    required this.haptic,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
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
        widget.haptic();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.82 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

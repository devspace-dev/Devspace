
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'duel_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final String category;
  final String mode;

  const MatchmakingScreen({
    super.key,
    required this.category,
    required this.mode,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showIntro = true;

  RealtimeChannel? _matchSubscription;
  bool _matchFound = false;
  String? _myUserId;
  bool _searching = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showIntro = false);
    });

    _startMatchmaking();
  }

  void _startMatchmaking() async {
    setState(() => _searching = true);
    final user = context.read<AuthProvider>().currentUserOrNull;
    if (user == null) return;
    _myUserId = user.id;

    // 1. Try to join an existing match
    final matchId = await SupabaseService.instance.findArenaMatch(widget.mode);
    
    if (matchId != null) {
      _matchFound = true;
      // Fetching actual player 1 logic would go here, using generic challenger for speed
      _navigateToDuel(matchId, isPlayer1: false, opponentId: 'placeholder'); 
      return;
    }

    // 2. If no match, create one and listen for player 2
    final newMatchId = await SupabaseService.instance.createArenaMatch(widget.mode);
    
    _matchSubscription = Supabase.instance.client
        .channel('public:arena_matches:id=eq.$newMatchId')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'arena_matches',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: newMatchId,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord['status'] == 'playing' && !_matchFound) {
                _matchFound = true;
                _matchSubscription?.unsubscribe();
                _navigateToDuel(newMatchId, isPlayer1: true, opponentId: newRecord['player2_id'].toString());
              }
            })
        .subscribe();

    // 30 second timeout for finding a match
    Future.delayed(const Duration(seconds: 30), () async {
      if (mounted && !_matchFound) {
        setState(() => _searching = false);
        _matchSubscription?.unsubscribe();
        try {
          await Supabase.instance.client.from('arena_matches').delete().eq('id', newMatchId);
        } catch(_) {}
      }
    });
  }

  void _navigateToDuel(String matchId, {required bool isPlayer1, required String opponentId}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          category: widget.category,
          mode: widget.mode,
          matchId: matchId,
          isPlayer1: isPlayer1,
          opponent: UserModel(
            id: opponentId,
            name: 'Online Challenger',
            handle: 'challenger',
            email: '',
            avatar: '',
            color: Colors.deepPurple,
            aura: 1000,
            roles: const [],
            year: '',
            branch: '',
            building: '',
            stack: const [],
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _matchSubscription?.unsubscribe();
    if (!_matchFound && _myUserId != null) {
      SupabaseService.instance.leaveMatchmakingPool(_myUserId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark radar background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
            Text(
              _searching ? 'SEARCHING FOR OPPONENT' : 'NO PLAYERS FOUND',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _searching ? Colors.white60 : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.category} • ${widget.mode}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(),
                      ),
                    ),
                    // Concentric circles
                    ...[280.0, 200.0, 120.0].map((size) {
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2), 
                            width: 1,
                          ),
                        ),
                      );
                    }),
                    // Better Radar sweep
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.05),
                              AppColors.primary.withValues(alpha: 0.25),
                              AppColors.primary.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 0.85, 0.98, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Center Logo (Subtle Pulse)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.code_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms, curve: Curves.easeInOut)
                    .boxShadow(
                      begin: BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                      end: BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 25,
                        spreadRadius: 6,
                      ),
                      duration: 1000.ms,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
                child: const Text(
                  'Cancel Search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_showIntro)
        Positioned.fill(
          child: Container(
            color: const Color(0xFF121212), // Solid black background to hide radar initially
            child: Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _LargeSwordsPainter(color: Colors.cyanAccent),
                ),
              )
              .animate()
              .scale(begin: const Offset(3, 3), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms)
              .shimmer(color: Colors.white.withValues(alpha: 0.8), duration: 800.ms, delay: 200.ms)
              .then(delay: 400.ms)
              .scale(begin: const Offset(1, 1), end: const Offset(0.8, 0.8), duration: 300.ms)
              .fadeOut(duration: 300.ms),
            ),
          )
          .animate()
          .fadeOut(delay: 1500.ms, duration: 400.ms),
        ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    const double step = 40;

    for (double i = 0; i < centerX; i += step) {
      canvas.drawLine(Offset(centerX + i, 0), Offset(centerX + i, size.height), paint);
      canvas.drawLine(Offset(centerX - i, 0), Offset(centerX - i, size.height), paint);
    }

    for (double i = 0; i < centerY; i += step) {
      canvas.drawLine(Offset(0, centerY + i), Offset(size.width, centerY + i), paint);
      canvas.drawLine(Offset(0, centerY - i), Offset(size.width, centerY - i), paint);
    }
    
    final crosshairPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;
    
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), crosshairPaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LargeSwordsPainter extends CustomPainter {
  final Color color;

  _LargeSwordsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    void drawMinimalSword(Offset bladeStart, Offset bladeEnd, Offset handleStart, Offset handleEnd, Color glowColor) {
      // 1. Sleek Core Glow
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.5)
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawLine(bladeStart, bladeEnd, glowPaint);

      // 2. Crisp Core
      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(bladeStart, bladeEnd, corePaint);

      // 3. Minimal Handle
      final handlePaint = Paint()
        ..color = Colors.white60
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(handleStart, handleEnd, handlePaint);

      // 4. Minimal Crossguard
      final crossguardPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      
      final lengthCross = 12.0;
      final dx = bladeEnd.dx - bladeStart.dx;
      final dy = bladeEnd.dy - bladeStart.dy;
      final perpCross = Offset(-dy, dx);
      final perpLenCross = perpCross.distance;
      if (perpLenCross > 0) {
        final crossVector = Offset(perpCross.dx / perpLenCross * lengthCross, perpCross.dy / perpLenCross * lengthCross);
        canvas.drawLine(bladeStart - crossVector, bladeStart + crossVector, crossguardPaint);
      }
    }

    final b1Start = Offset(size.width * 0.35, size.height * 0.65);
    final b1End = Offset(size.width * 0.9, size.height * 0.1);
    final h1Start = Offset(size.width * 0.35, size.height * 0.65);
    final h1End = Offset(size.width * 0.15, size.height * 0.85);

    final b2Start = Offset(size.width * 0.65, size.height * 0.65);
    final b2End = Offset(size.width * 0.1, size.height * 0.1);
    final h2Start = Offset(size.width * 0.65, size.height * 0.65);
    final h2End = Offset(size.width * 0.85, size.height * 0.85);

    // Left Sword
    drawMinimalSword(b1Start, b1End, h1Start, h1End, AppColors.primary);
    // Right Sword
    drawMinimalSword(b2Start, b2End, h2Start, h2End, Colors.cyanAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

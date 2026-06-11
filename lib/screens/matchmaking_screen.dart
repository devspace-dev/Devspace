
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
              child: _BattleTypeIntro(
                category: widget.category,
                mode: widget.mode,
              )
              .animate()
              .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms)
              .then(delay: 500.ms)
              .scale(begin: const Offset(1, 1), end: const Offset(0.9, 0.9), duration: 400.ms)
              .fadeOut(duration: 400.ms),
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

class _BattleTypeIntro extends StatelessWidget {
  final String category;
  final String mode;

  const _BattleTypeIntro({
    required this.category,
    required this.mode,
  });

  Color _getModeColor() {
    final modeUpper = mode.toUpperCase();
    if (modeUpper.contains('REFLEX')) {
      return const Color(0xFFFFD300); // Bright Yellow
    } else if (modeUpper.contains('COMBAT')) {
      return const Color(0xFFFF375F); // Bright Crimson
    } else if (modeUpper.contains('TEAM') || modeUpper.contains('DUEL')) {
      return const Color(0xFF32D74B); // Bright Green
    }
    return AppColors.primary; // Orange
  }

  IconData _getModeIcon() {
    final modeUpper = mode.toUpperCase();
    if (modeUpper.contains('REFLEX')) {
      return Icons.bolt_rounded;
    } else if (modeUpper.contains('COMBAT')) {
      return Icons.terminal_rounded;
    } else if (modeUpper.contains('TEAM')) {
      return Icons.groups_rounded;
    }
    return Icons.local_fire_department_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getModeColor();
    final modeIcon = _getModeIcon();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing, rotating futuristic rings
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer dotted/segmented ring rotating clockwise
            Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 6.seconds, begin: 0, end: 1),

            // Inner sweep gradient rotating counter-clockwise
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    themeColor.withValues(alpha: 0.02),
                    themeColor.withValues(alpha: 0.2),
                    themeColor.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.8, 0.95, 1.0],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2.5.seconds, begin: 0, end: -1),

            // central neon glass orb with icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.4),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  modeIcon,
                  size: 40,
                  color: themeColor,
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
              duration: 1.seconds,
              curve: Curves.easeInOut,
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Category Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            category.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: themeColor,
              letterSpacing: 2,
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        // Mode Title with customized styling
        Text(
          mode.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
            height: 1.1,
            shadows: [
              Shadow(
                color: themeColor.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 350.ms, duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 350.ms, duration: 500.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        // Arena Status Pulse Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 600.ms),
            const SizedBox(width: 8),
            Text(
              'ARENA INITIALIZING...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white30,
                letterSpacing: 1.5,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms),
      ],
    );
  }
}

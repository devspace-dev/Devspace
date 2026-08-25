import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'duel_screen.dart';

class WaitingForOpponentScreen extends StatefulWidget {
  final String requestId;
  final UserModel opponent;
  final String category;
  final String mode;

  const WaitingForOpponentScreen({
    super.key,
    required this.requestId,
    required this.opponent,
    required this.category,
    required this.mode,
  });

  @override
  State<WaitingForOpponentScreen> createState() => _WaitingForOpponentScreenState();
}

class _WaitingForOpponentScreenState extends State<WaitingForOpponentScreen> {
  RealtimeChannel? _subscription;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _listenForStatusChange();
  }

  void _listenForStatusChange() {
    _subscription = SupabaseService.instance.listenToDuelRequestStatus(
      widget.requestId,
      (request) {
        if (!mounted || _cancelled) return;
        final status = request['status'];
        if (status == 'accepted') {
          _subscription?.unsubscribe();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DuelScreen(
                category: widget.category,
                mode: widget.mode,
                matchId: widget.requestId,
                isPlayer1: true,
                opponent: widget.opponent,
              ),
            ),
          );
        } else if (status == 'declined' || status == 'cancelled') {
          _subscription?.unsubscribe();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.opponent.name} declined the challenge.')),
            );
            Navigator.pop(context);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Radar effect
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: const Duration(seconds: 2))
                .fadeOut(duration: const Duration(seconds: 2)),

                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.bg2For(context),
                  backgroundImage: widget.opponent.avatar.isNotEmpty ? NetworkImage(widget.opponent.avatar) : null,
                  child: widget.opponent.avatar.isEmpty
                      ? Text(widget.opponent.name[0], style: const TextStyle(fontSize: 24, color: Colors.white))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Waiting for ${widget.opponent.name}...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: const Duration(seconds: 1)).fadeOut(duration: const Duration(seconds: 1)),
            const SizedBox(height: 12),
            const Text(
              'Challenge sent! Waiting for them to accept.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () async {
                _cancelled = true;
                await SupabaseService.instance.updateDuelRequestStatus(widget.requestId, 'cancelled');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Cancel Request', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}

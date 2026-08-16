import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/badge_model.dart';

class TierUpDialog extends StatelessWidget {
  final int aura;
  final String tierName;

  const TierUpDialog({
    super.key,
    required this.aura,
    required this.tierName,
  });

  static void show(BuildContext context, int aura, String tierName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tier Up',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return TierUpDialog(aura: aura, tierName: tierName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = getBadge(aura);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badge.color.withValues(alpha: 0.3),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            ).then().scale(
              begin: const Offset(1.5, 1.5),
              end: const Offset(1, 1),
              duration: 2.seconds,
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TIER UP!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                  
                  const SizedBox(height: 32),
                  
                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: badge.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: badge.color, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ).animate()
                    .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 800.ms)
                    .shimmer(delay: 1.seconds, duration: 2.seconds),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    badge.name,
                    style: GoogleFonts.plusJakartaSans(
                      color: badge.color,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const SizedBox(height: 48),
                  
                  // Shareable Card Preview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOU REACHED',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$aura Aura',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.2),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: badge.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ).animate().fadeIn(delay: 1200.ms),
                  
                  const SizedBox(height: 16),
                  
                  TextButton.icon(
                    onPressed: () {
                      // Logic for sharing would go here
                    },
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    label: const Text('SHARE ACHIEVEMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ).animate().fadeIn(delay: 1400.ms),
                ],
              ),
            ),
          ),
          
          // Particles or Confetti would be nice here
        ],
      ),
    );
  }
}

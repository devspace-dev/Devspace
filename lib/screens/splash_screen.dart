import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/devspace_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Background ambient glow
          Align(
            alignment: const Alignment(0, -0.15),
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x1AFF7A00),
                    Color(0x00FF7A00),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 3000.ms,
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                curve: Curves.easeInOutSine,
              ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DevSpaceLogo(size: 110).animate()
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .scale(
                        duration: 800.ms,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      )
                      .shimmer(delay: 1200.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 24),
                    Text(
                      'DevSpace',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                    ).animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 12),
                    Text(
                      'Student builders, one shared space.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8B95A5),
                        letterSpacing: 0.2,
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Text(
              'STUDENT DEVELOPER COMMUNITY',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF4B5563),
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}

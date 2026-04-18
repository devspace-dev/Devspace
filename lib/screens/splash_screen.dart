import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/devspace_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090D),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.22),
                  radius: 1.05,
                  colors: [
                    Color(0xFF111723),
                    Color(0xFF090C12),
                    Color(0xFF05070B),
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x223DE1FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 3200.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
              ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DevSpaceLogo(size: 118).animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        duration: 760.ms,
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                      ),
                    const SizedBox(height: 28),
                    Text(
                      'DevSpace',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.3,
                        color: const Color(0xFFF6F8FC),
                      ),
                    ).animate()
                      .fadeIn(delay: 180.ms, duration: 500.ms)
                      .slideY(begin: 0.18, end: 0),
                    const SizedBox(height: 10),
                    Text(
                      'Student builders, one shared space.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9AA3B2),
                        letterSpacing: 0.1,
                      ),
                    ).animate().fadeIn(delay: 340.ms, duration: 520.ms),
                    const SizedBox(height: 34),
                    Container(
                      width: 124,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3DE1FF),
                                Color(0xFF9EF3FF),
                              ],
                            ),
                          ),
                        ).animate()
                          .scaleX(
                            duration: 1600.ms,
                            begin: 0,
                            end: 1,
                            alignment: Alignment.centerLeft,
                            curve: Curves.easeInOutCubic,
                          ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Text(
              'student developer community',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6C7482),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 520.ms),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../widgets/devspace_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.15,
                  colors: [
                    Color(0xFF171C26),
                    Color(0xFF0B0F15),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.18, 1.18))
             .move(duration: 3.seconds, begin: Offset.zero, end: const Offset(-18, 16)),
          ),

          Positioned(
            bottom: -90,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF97316).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 3400.ms, begin: const Offset(1, 1), end: const Offset(1.12, 1.12))
             .move(duration: 3400.ms, begin: Offset.zero, end: const Offset(12, -12)),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DevSpaceLogo(size: 132).animate()
                   .scale(duration: 850.ms, curve: Curves.easeOutBack)
                   .fadeIn(duration: 500.ms)
                   .shimmer(delay: 1.seconds, duration: 1400.ms),

                  const SizedBox(height: 28),

                  Text(
                    'DevSpace',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ).animate()
                   .fadeIn(delay: 350.ms, duration: 600.ms)
                   .slideY(begin: 0.16, end: 0),

                  const SizedBox(height: 10),

                  Text(
                    'Build. Learn. Ship with your campus crew.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ).animate()
                   .fadeIn(delay: 700.ms, duration: 600.ms),

                  const SizedBox(height: 36),

                  Container(
                    width: 156,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.55),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .fade(duration: 900.ms, begin: 0.35, end: 1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ).animate()
                             .scaleX(
                               duration: 2.seconds,
                               begin: 0,
                               end: 1,
                               alignment: Alignment.centerLeft,
                               curve: Curves.easeInOutQuart,
                             ),
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                   .fadeIn(delay: 950.ms, duration: 500.ms)
                   .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Text(
              'for student builders',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.34),
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ).animate()
             .fadeIn(delay: 1200.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

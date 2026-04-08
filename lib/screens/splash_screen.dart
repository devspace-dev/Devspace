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
    Future.delayed(const Duration(milliseconds: 2800), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Premium animated background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),
          
          // Glow blob top-right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
             .move(duration: 3.seconds, begin: Offset.zero, end: const Offset(-20, 20)),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Logo
                const DevSpaceLogo(size: 104).animate()
                 .scale(duration: 800.ms, curve: Curves.easeOutBack)
                 .shimmer(delay: 1.seconds, duration: 1500.ms),
                
                const SizedBox(height: 32),
                
                // App name
                Text(
                  'DevSpace',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ).animate()
                 .fadeIn(delay: 400.ms, duration: 600.ms)
                 .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 12),
                
                // Tagline
                Text(
                  'The space for student builders',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ).animate()
                 .fadeIn(delay: 800.ms, duration: 600.ms),
                
                const SizedBox(height: 60),
                
                // Loading bar
                Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ).animate().scaleX(duration: 2.seconds, begin: 0, end: 1, curve: Curves.easeInOutQuart),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

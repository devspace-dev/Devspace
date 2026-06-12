import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AuthIntroScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AuthIntroScreen({super.key, required this.onSuccess});

  @override
  State<AuthIntroScreen> createState() => _AuthIntroScreenState();
}

class _AuthIntroScreenState extends State<AuthIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _openAuth({required bool signUp}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onSuccess: widget.onSuccess,
          startInSignUp: signUp,
          closeOnSuccess: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep overlay style consistent with the light theme of this intro screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFCFBFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.1),
            radius: 1.2,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFCFBFA),
              Color(0xFFFAF8F5),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top spacing spacer
                        const SizedBox(height: 20),

                        // Branding & Illustration Group
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Orbit line + floating rocket logo
                            SizedBox(
                              width: 320,
                              height: 240,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Oval Orbit
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: OrbitPainter(),
                                    ),
                                  ),
                                  // Floating Rocket Image
                                  AnimatedBuilder(
                                    animation: _floatAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, _floatAnimation.value),
                                        child: child,
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      width: 108,
                                      height: 108,
                                      fit: BoxFit.contain,
                                      color: const Color(0xFFFF5E00),
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.rocket_launch_rounded,
                                        color: Color(0xFFFF5E00),
                                        size: 96,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // DevSpace main typography
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Dev',
                                    style: TextStyle(color: Color(0xFF1E293B)),
                                  ),
                                  TextSpan(
                                    text: 'Space',
                                    style: TextStyle(color: Color(0xFFFF5E00)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            // Catchy student builders subtitle
                            Text(
                              'Student builders,\none shared space.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Small accent pill line
                            Container(
                              width: 46,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5E00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),

                        // Bottom Actions Group
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, top: 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Get Started Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5E00),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => _openAuth(signUp: true),
                                  child: Text(
                                    'Get Started',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Already have an account Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => _openAuth(signUp: false),
                                  child: Text(
                                    'I already have an account',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFF5E00).withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-18 * pi / 180); // tilt by -18 degrees

    // Ellipse dimensions
    final double rx = size.width * 0.44;
    final double ry = size.height * 0.35;

    final rect = Rect.fromLTRB(-rx, -ry, rx, ry);
    canvas.drawOval(rect, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = const Color(0xFFFF5E00)
      ..style = PaintingStyle.fill;

    // Dot 1: left side (around 195 degrees)
    const double theta1 = 195 * pi / 180;
    final p1 = Offset(rx * cos(theta1), ry * sin(theta1));
    canvas.drawCircle(p1, 5.0, dotPaint);

    // Dot 2: top right side (around 38 degrees)
    const double theta2 = 38 * pi / 180;
    final p2 = Offset(rx * cos(theta2), ry * sin(theta2));
    canvas.drawCircle(p2, 5.0, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

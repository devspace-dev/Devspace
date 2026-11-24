import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/glitch.dart';
import '../../../core/widgets/segment_bar.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  int _progressStep = 1;

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    // Progress through 6 segments over 1000ms, then route
    _timer = Timer.periodic(const Duration(milliseconds: 160), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_progressStep < 6) {
        setState(() => _progressStep++);
      } else {
        timer.cancel();
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    if (GoRouter.maybeOf(context) == null) return;
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) {
        context.go('/auth-intro');
      } else if (!user.profileCompleted) {
        context.go('/profile-setup');
      } else {
        context.go('/play');
      }
    } catch (_) {
      // In test environments or uninitialized service
      if (GoRouter.maybeOf(context) != null) {
        context.go('/play');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Ds.ink,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Slanted Ds.surface band behind mascot (rotated -8 degrees)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            child: Transform.rotate(
              angle: -8 * 3.14159265 / 180,
              child: Container(
                width: MediaQuery.of(context).size.width * 1.4,
                height: 140,
                color: Ds.surface,
              ),
            ),
          ),

          // Main Center Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Mascot Glitch (200px, hype mood)
                  const Glitch(size: 200, mood: GlitchMood.hype),
                  const SizedBox(height: 24),

                  // Wordmark: DEV in bone + SPACE in yellow (Anton 64)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DEV',
                        style: DsText.h1.copyWith(
                          fontSize: 64,
                          color: Ds.bone,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'SPACE',
                        style: DsText.h1.copyWith(
                          fontSize: 64,
                          color: Ds.aura,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Student builders. One shared arena.',
                    style: DsText.label.copyWith(
                      color: Ds.muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Loading Segment Bar & Caption
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  child: SegmentBar(
                    total: 6,
                    current: _progressStep,
                    filledColor: Ds.aura,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading your Aura...',
                  style: DsText.caption.copyWith(
                    color: Ds.aura,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

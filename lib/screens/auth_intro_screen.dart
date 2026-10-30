import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/glitch.dart';
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
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Ds.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Ds.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Hero Mascot & Branding Group
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Glitch Mascot with slanted background pill
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -8 * 3.14159 / 180,
                        child: Container(
                          width: 240,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Ds.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Ds.border, width: 2),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: child,
                          );
                        },
                        child: const Glitch(size: 150, mood: GlitchMood.hype),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Wordmark: DEV (bone) + SPACE (yellow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DEV',
                        style: DsText.h1.copyWith(
                          fontSize: 48,
                          color: Ds.bone,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'SPACE',
                        style: DsText.h1.copyWith(
                          fontSize: 48,
                          color: Ds.aura,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  Text(
                    'Student builders.\nOne shared arena.',
                    textAlign: TextAlign.center,
                    style: DsText.label.copyWith(
                      color: Ds.muted,
                      height: 1.4,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // Bottom Actions Group (Chunky 3D Buttons)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DsButton(
                      label: 'Get Started',
                      kind: DsButtonKind.aura,
                      onPressed: () => _openAuth(signUp: true),
                    ),
                    const SizedBox(height: 12),
                    DsButton(
                      label: 'I already have an account',
                      kind: DsButtonKind.bone,
                      onPressed: () => _openAuth(signUp: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

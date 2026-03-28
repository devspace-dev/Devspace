import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'login_screen.dart';

class AuthIntroScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AuthIntroScreen({super.key, required this.onSuccess});

  @override
  State<AuthIntroScreen> createState() => _AuthIntroScreenState();
}

class _AuthIntroScreenState extends State<AuthIntroScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const List<_IntroSlideData> _slides = [
    _IntroSlideData(
      title: 'Post your build\njourney publicly',
      subtitle:
          'Share project updates, hackathon progress, and what you are shipping with your college dev circle.',
      topLabel: 'Build In Public',
      accent: Color(0xFF7CFF31),
      background: Color(0xFFA6FF1D),
      foreground: Color(0xFF101410),
      panel: Color(0xFFF7FFD8),
      icon: Icons.rocket_launch_rounded,
      statLeft: 'Project updates',
      statRight: 'Hackathon logs',
    ),
    _IntroSlideData(
      title: 'Turn doubts into\nuseful Q&A threads',
      subtitle:
          'Ask technical questions, get practical replies, and keep solved answers visible for the next student.',
      topLabel: 'Ask Better',
      accent: Color(0xFFFF7AB8),
      background: Color(0xFF0E0E12),
      foreground: Colors.white,
      panel: Color(0xFF1B1B24),
      icon: Icons.forum_rounded,
      statLeft: 'Debug faster',
      statRight: 'Solved replies',
    ),
    _IntroSlideData(
      title: 'Find the people\nwho are actually building',
      subtitle:
          'Discover students by stack, branch, and projects so collaboration starts from shared work, not random chat.',
      topLabel: 'Find Builders',
      accent: Color(0xFFFF4FA1),
      background: Color(0xFFFF5DA9),
      foreground: Color(0xFF1A0F18),
      panel: Color(0xFFFFD2E5),
      icon: Icons.groups_rounded,
      statLeft: 'Real profiles',
      statRight: 'Same campus',
    ),
    _IntroSlideData(
      title: 'Earn aura for\nhelpful contribution',
      subtitle:
          'Posts, comments, and accepted answers build your visible builder identity from the first week.',
      topLabel: 'Grow Reputation',
      accent: Color(0xFFFFF14A),
      background: Color(0xFFFFE82C),
      foreground: Color(0xFF17120A),
      panel: Color(0xFFFFF7B1),
      icon: Icons.auto_awesome_rounded,
      statLeft: 'Helpful replies',
      statRight: 'Visible aura',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _next() async {
    if (_pageIndex == _slides.length - 1) {
      await _openAuth(signUp: true);
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _pageIndex = index);
            },
            itemBuilder: (context, index) {
              return _FullScreenIntroSlide(data: _slides[index]);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          'DevSpace',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _slides[_pageIndex].foreground,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _openAuth(signUp: false),
                        child: Text(
                          'Sign in',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _slides[_pageIndex].foreground.withValues(
                              alpha: 0.82,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      ...List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: index == _pageIndex ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: index == _pageIndex
                                ? _slides[_pageIndex].foreground
                                : _slides[_pageIndex].foreground
                                    .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 156,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          onPressed: _next,
                          child: Text(
                            _pageIndex == _slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openAuth(signUp: true),
                      child: Text(
                        'Create account',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _slides[_pageIndex].foreground.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroSlideData {
  final String title;
  final String subtitle;
  final String topLabel;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color panel;
  final IconData icon;
  final String statLeft;
  final String statRight;

  const _IntroSlideData({
    required this.title,
    required this.subtitle,
    required this.topLabel,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.panel,
    required this.icon,
    required this.statLeft,
    required this.statRight,
  });
}

class _FullScreenIntroSlide extends StatelessWidget {
  final _IntroSlideData data;

  const _FullScreenIntroSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.background,
            Color.lerp(data.background, Colors.white, 0.08)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 86, 18, 100),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 44,
                      bottom: 124,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(42),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 86,
                      child: Container(
                        decoration: BoxDecoration(
                          color: data.background,
                          borderRadius: BorderRadius.circular(42),
                          border: Border.all(
                            color: data.foreground.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 26,
                              left: 24,
                              child: Text(
                                data.topLabel,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: data.foreground.withValues(alpha: 0.62),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 86,
                              left: 24,
                              right: 24,
                              child: _HeroMock(data: data),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                        decoration: BoxDecoration(
                          color: data.panel,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.4,
                                height: 1.02,
                                color: data.foreground,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.subtitle,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.48,
                                color: data.foreground.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
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
  }
}

class _HeroMock extends StatelessWidget {
  final _IntroSlideData data;

  const _HeroMock({required this.data});

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.black.withValues(
      alpha: data.background.computeLuminance() > 0.5 ? 0.1 : 0.28,
    );

    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 22,
            left: 16,
            child: Transform.rotate(
              angle: -0.12,
              child: _MockCard(
                width: 146,
                height: 96,
                color: cardColor,
                accent: data.accent,
                foreground: data.foreground,
                label: data.statLeft,
                icon: data.icon,
              ),
            ),
          ),
          Positioned(
            top: 58,
            right: 16,
            child: Transform.rotate(
              angle: 0.11,
              child: _MockCard(
                width: 142,
                height: 92,
                color: cardColor,
                accent: data.foreground.withValues(alpha: 0.85),
                foreground: data.foreground,
                label: data.statRight,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
          Container(
            width: 162,
            height: 162,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(42),
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.24),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  data.icon,
                  size: 42,
                  color: data.accent,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: data.foreground,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Built for student devs',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: data.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Color accent;
  final Color foreground;
  final String label;
  final IconData icon;

  const _MockCard({
    required this.width,
    required this.height,
    required this.color,
    required this.accent,
    required this.foreground,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

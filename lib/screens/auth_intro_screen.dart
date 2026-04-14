import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/devspace_logo.dart';
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
      label: 'Build In Public',
      title: 'Share your builder journey with the right people',
      body:
          'Post project updates, hackathon progress, and small wins in a community made for student developers.',
      accent: Color(0xFF5AB8FF),
      background: Color(0xFF08111B),
      surface: Color(0xFF0E1824),
      heroTitle: 'Campus Feed',
      heroSubtitle: 'Project updates, build logs, and useful momentum.',
      points: ['Project updates', 'Hackathon logs', 'Build streaks'],
      metricAValue: '128',
      metricALabel: 'active builders',
      metricBValue: '42',
      metricBLabel: 'new updates',
      icon: Icons.rocket_launch_rounded,
    ),
    _IntroSlideData(
      label: 'Practical Q&A',
      title: 'Turn doubts into threads that actually help',
      body:
          'Ask technical questions, get clear replies, and keep solved answers visible for the next student.',
      accent: Color(0xFFFF8FA8),
      background: Color(0xFF140B12),
      surface: Color(0xFF1D1019),
      heroTitle: 'Useful Q&A',
      heroSubtitle: 'Practical replies that stay easy to revisit.',
      points: ['Bug fixes', 'System design', 'Solved replies'],
      metricAValue: '34',
      metricALabel: 'solved threads',
      metricBValue: 'Fast',
      metricBLabel: 'peer replies',
      icon: Icons.forum_rounded,
    ),
    _IntroSlideData(
      label: 'Find Builders',
      title: 'Discover people by stack, branch, and what they ship',
      body:
          'Find students building with Flutter, AI, web, or systems and grow a real dev circle on campus.',
      accent: Color(0xFFFFB454),
      background: Color(0xFF17100A),
      surface: Color(0xFF22170E),
      heroTitle: 'Builder Discovery',
      heroSubtitle: 'Profiles designed around work, stack, and momentum.',
      points: ['Flutter', 'AI', 'Open source'],
      metricAValue: 'Real',
      metricALabel: 'student profiles',
      metricBValue: 'Same',
      metricBLabel: 'college network',
      icon: Icons.groups_rounded,
    ),
    _IntroSlideData(
      label: 'Earn Aura',
      title: 'Grow a visible reputation by being useful',
      body:
          'Posts, comments, and accepted answers earn aura so contribution feels meaningful from day one.',
      accent: Color(0xFFB8FF65),
      background: Color(0xFF0C130B),
      surface: Color(0xFF141D13),
      heroTitle: 'Visible Progress',
      heroSubtitle: 'Your contribution turns into momentum over time.',
      points: ['Helpful replies', 'Accepted answers', 'Visible progress'],
      metricAValue: '+5',
      metricALabel: 'for helping',
      metricBValue: 'Compounds',
      metricBLabel: 'reputation',
      icon: Icons.auto_awesome_rounded,
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
    final active = _slides[_pageIndex];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        color: active.background,
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -80,
              child: _GlowOrb(
                color: active.accent,
                size: 300,
                opacity: 0.16,
              ),
            ),
            Positioned(
              bottom: -120,
              left: -60,
              child: _GlowOrb(
                color: active.accent,
                size: 240,
                opacity: 0.08,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                child: Column(
                  children: [
                    _IntroHeader(
                      onSignIn: () => _openAuth(signUp: false),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (index) {
                          setState(() => _pageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return _IntroPage(data: _slides[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _IntroActions(
                      activeIndex: _pageIndex,
                      total: _slides.length,
                      accent: active.accent,
                      onNext: _next,
                      onCreateAccount: () => _openAuth(signUp: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlideData {
  final String label;
  final String title;
  final String body;
  final Color accent;
  final Color background;
  final Color surface;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> points;
  final String metricAValue;
  final String metricALabel;
  final String metricBValue;
  final String metricBLabel;
  final IconData icon;

  const _IntroSlideData({
    required this.label,
    required this.title,
    required this.body,
    required this.accent,
    required this.background,
    required this.surface,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.points,
    required this.metricAValue,
    required this.metricALabel,
    required this.metricBValue,
    required this.metricBLabel,
    required this.icon,
  });
}

class _IntroHeader extends StatelessWidget {
  final VoidCallback onSignIn;

  const _IntroHeader({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DevSpaceLogo(size: 28, elevated: false),
              const SizedBox(width: 10),
              Text(
                'DevSpace',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSignIn,
          child: Text(
            'Sign in',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroPage extends StatelessWidget {
  final _IntroSlideData data;

  const _IntroPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: compact ? 104 : 132,
                      height: compact ? 104 : 132,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: data.surface,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: data.accent.withValues(alpha: 0.2),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: DevSpaceLogo(elevated: false),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: data.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: data.background,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                data.icon,
                                size: 16,
                                color: const Color(0xFF081018),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 36),
                  Text(
                    data.label.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: data.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: compact ? 30 : 40,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                      letterSpacing: -1.4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.body,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: compact ? 20 : 28),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(compact ? 18 : 20),
                    decoration: BoxDecoration(
                      color: data.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.heroTitle,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: compact ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.heroSubtitle,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: compact ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: data.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                data.icon,
                                color: data.accent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ...data.points.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: data.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: compact ? 12.8 : 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                value: data.metricAValue,
                                label: data.metricALabel,
                                accent: data.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricTile(
                                value: data.metricBValue,
                                label: data.metricBLabel,
                                accent: data.accent,
                              ),
                            ),
                          ],
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
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _MetricTile({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroActions extends StatelessWidget {
  final int activeIndex;
  final int total;
  final Color accent;
  final VoidCallback onNext;
  final VoidCallback onCreateAccount;

  const _IntroActions({
    required this.activeIndex,
    required this.total,
    required this.accent,
    required this.onNext,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ...List.generate(
              total,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: index == activeIndex ? 30 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: index == activeIndex
                      ? accent
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 164,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                onPressed: onNext,
                child: Text(
                  activeIndex == total - 1 ? 'Get Started' : 'Next',
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
            onPressed: onCreateAccount,
            child: Text(
              'Create account',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.84),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          'Post project updates, hackathon progress, and small wins in a feed made for student developers.',
      accent: Color(0xFF4FD1FF),
      accentSoft: Color(0xFF142636),
      bgTop: Color(0xFF0A1220),
      bgBottom: Color(0xFF050814),
      cardColor: Color(0xFF0F1726),
      heroTitle: 'Campus Feed',
      heroSubtitle: 'Updates from real builders in your college',
      chips: ['Project updates', 'Hackathon logs', 'Build streak'],
      statLeftValue: '128',
      statLeftLabel: 'Active builders',
      statRightValue: '42',
      statRightLabel: 'New updates',
      icon: Icons.rocket_launch_rounded,
    ),
    _IntroSlideData(
      label: 'Practical Q&A',
      title: 'Turn doubts into threads that actually help',
      body:
          'Ask technical questions, get clear replies, and keep solved answers visible for the next student.',
      accent: Color(0xFFFF8AB8),
      accentSoft: Color(0xFF311826),
      bgTop: Color(0xFF140E19),
      bgBottom: Color(0xFF09070D),
      cardColor: Color(0xFF17111E),
      heroTitle: 'Useful Q&A',
      heroSubtitle: 'Practical replies that stay easy to revisit',
      chips: ['Bug fixes', 'System design', 'Solved replies'],
      statLeftValue: '34',
      statLeftLabel: 'Solved threads',
      statRightValue: 'Fast',
      statRightLabel: 'Peer replies',
      icon: Icons.forum_rounded,
    ),
    _IntroSlideData(
      label: 'Find Builders',
      title: 'Discover people by stack, branch, and what they ship',
      body:
          'Find students building with Flutter, AI, web, or systems and grow a real dev circle on campus.',
      accent: Color(0xFFFFB454),
      accentSoft: Color(0xFF352515),
      bgTop: Color(0xFF171015),
      bgBottom: Color(0xFF09070A),
      cardColor: Color(0xFF1A1318),
      heroTitle: 'Builder Discovery',
      heroSubtitle: 'Profiles designed around work, stack, and momentum',
      chips: ['Flutter', 'AI', 'Open source'],
      statLeftValue: 'Real',
      statLeftLabel: 'Student profiles',
      statRightValue: 'Same',
      statRightLabel: 'College network',
      icon: Icons.groups_rounded,
    ),
    _IntroSlideData(
      label: 'Earn Aura',
      title: 'Grow a visible reputation by being useful',
      body:
          'Posts, comments, and accepted answers earn aura so contribution feels meaningful from day one.',
      accent: Color(0xFFB8FF65),
      accentSoft: Color(0xFF21331A),
      bgTop: Color(0xFF0C1610),
      bgBottom: Color(0xFF060A07),
      cardColor: Color(0xFF101A12),
      heroTitle: 'Visible Progress',
      heroSubtitle: 'Your contribution turns into momentum over time',
      chips: ['Helpful replies', 'Accepted answers', 'Visible progress'],
      statLeftValue: '+5',
      statLeftLabel: 'For helping',
      statRightValue: 'Compounds',
      statRightLabel: 'Reputation',
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
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [active.bgTop, active.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                _IntroHeader(
                  onSignIn: () => _openAuth(signUp: false),
                ),
                const SizedBox(height: 18),
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
                  onNext: _next,
                  onCreateAccount: () => _openAuth(signUp: true),
                ),
              ],
            ),
          ),
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
  final Color accentSoft;
  final Color bgTop;
  final Color bgBottom;
  final Color cardColor;
  final String heroTitle;
  final String heroSubtitle;
  final List<String> chips;
  final String statLeftValue;
  final String statLeftLabel;
  final String statRightValue;
  final String statRightLabel;
  final IconData icon;

  const _IntroSlideData({
    required this.label,
    required this.title,
    required this.body,
    required this.accent,
    required this.accentSoft,
    required this.bgTop,
    required this.bgBottom,
    required this.cardColor,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.chips,
    required this.statLeftValue,
    required this.statLeftLabel,
    required this.statRightValue,
    required this.statRightLabel,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            'DevSpace',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
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
              color: Colors.white,
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
        final compact = constraints.maxHeight < 680;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VisualPanel(
              data: data,
              compact: compact,
              height: compact ? 250 : 310,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 20 : 24),
                decoration: BoxDecoration(
                  color: data.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.label.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: data.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: compact ? 31 : 36,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                        letterSpacing: -1.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.body,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: compact ? 13.5 : 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VisualPanel extends StatelessWidget {
  final _IntroSlideData data;
  final bool compact;
  final double height;

  const _VisualPanel({
    required this.data,
    required this.compact,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            data.accentSoft,
            data.cardColor,
            Colors.black.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -26,
            right: -14,
            child: Container(
              width: compact ? 120 : 150,
              height: compact ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.accent.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Made for student builders',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: compact ? 56 : 68,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: data.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(data.icon, color: data.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.heroTitle,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF12161D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.heroSubtitle,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF616876),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.chips
                        .map(
                          (chip) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: data.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chip,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF12161D),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: data.statLeftValue,
                          label: data.statLeftLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          value: data.statRightValue,
                          label: data.statRightLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: compact ? 22 : 28,
            bottom: compact ? 18 : 22,
            child: Container(
              width: compact ? 68 : 78,
              height: compact ? 68 : 78,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: data.accent.withValues(alpha: 0.26),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: compact ? 30 : 34,
                  color: data.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF12161D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF616876),
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
  final VoidCallback onNext;
  final VoidCallback onCreateAccount;

  const _IntroActions({
    required this.activeIndex,
    required this.total,
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
                width: index == activeIndex ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: index == activeIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.24),
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

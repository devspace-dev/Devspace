import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/challenge_tier_card.dart';
import 'weekly_challenge_registration_screen.dart';
import 'weekly_free_challenge_screen.dart';

class WeeklyChallengeScreen extends StatefulWidget {
  const WeeklyChallengeScreen({super.key});

  @override
  State<WeeklyChallengeScreen> createState() => _WeeklyChallengeScreenState();
}

class _WeeklyChallengeScreenState extends State<WeeklyChallengeScreen> {
  int _selectedTab = 1; // Default to Premium/Paid to encourage it

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final engagement = context.watch<EngagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Weekly Challenge'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Path',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Level up your skills with weekly curated challenges.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Custom Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.bg3For(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'FREE',
                          isSelected: _selectedTab == 0,
                          onPressed: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'PREMIUM',
                          isSelected: _selectedTab == 1,
                          onPressed: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SingleChildScrollView(
                    key: ValueKey(_selectedTab),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: _selectedTab == 0 
                      ? _buildFreeTier(context)
                      : _buildPaidTier(context, me, engagement),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeTier(BuildContext context) {
    return Column(
      children: [
        ChallengeTierCard(
          key: const ValueKey('free_tier'),
          isComingSoon: true,
          title: 'Tech Stack Questions',
          description: 'Sharpen your coding skills with weekly questions tailored to your tech stack.',
          icon: Icons.code_rounded,
          accentColor: AppColors.blue,
          features: const [
            'Weekly Tech Stack Questions',
            'Basic Performance Analytics',
            'Community Leaderboard Access',
            'Peer Comparison'
          ],
          buttonText: 'Coming Soon',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyFreeChallengeScreen()),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPaidTier(BuildContext context, dynamic me, EngagementProvider engagement) {
    return Column(
      children: [
        ChallengeTierCard(
          key: const ValueKey('paid_tier'),
          isPremium: true,
          isComingSoon: true,
          title: 'Career & Skill Growth',
          price: 'Rs 29 / WEEK',
          description: 'The ultimate package for builders who are serious about their career and skill development.',
          icon: Icons.rocket_launch_rounded,
          accentColor: AppColors.indigo,
          isEnrolled: engagement.isWeeklyChallengeEnrolled,
          isLoading: engagement.isEnrollingWeekly,
          features: const [
            'Premium Tech Questions',
            'Personalized Career Roadmap',
            'Skill Growth Strategy',
            'Elite Mentor Feedback',
            'Premium Learning Resources',
            'Priority Placement Support'
          ],
          buttonText: 'Coming Soon',
          onPressed: () {
            if (engagement.isWeeklyChallengeEnrolled) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Viewing premium details...')),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklyChallengeRegistrationScreen(),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        _buildBenefitSection(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBenefitSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Premium?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 16),
        const _BenefitItem(
          icon: Icons.map_rounded,
          title: 'Career Roadmap',
          subtitle: 'Step-by-step guidance to reach your dream role.',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        const _BenefitItem(
          icon: Icons.trending_up_rounded,
          title: 'Skill Growth',
          subtitle: 'Identify and bridge your technical gaps effectively.',
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        const _BenefitItem(
          icon: Icons.verified_user_rounded,
          title: 'Mentor Feedback',
          subtitle: 'Direct feedback from industry experts on your code.',
          color: AppColors.indigo,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bgFor(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? AppColors.textFor(context) : AppColors.text3For(context),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text2For(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

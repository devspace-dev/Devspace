import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/info_block.dart';
import '../widgets/weekly_challenge_card.dart';
import 'weekly_challenge_registration_screen.dart';

class WeeklyChallengeScreen extends StatelessWidget {
  const WeeklyChallengeScreen({super.key});

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
        title: const Text('Weekly Coding Challenge'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Coding Challenge',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs 59 per participant, curated for career goals.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text3For(context),
                  ),
                ),
                const SizedBox(height: 24),
                WeeklyChallengeCard(
                  user: me,
                  isEnrolled: engagement.isWeeklyChallengeEnrolled,
                  isLoading: engagement.isEnrollingWeekly,
                  onDetailsPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Weekly challenge details and submission portal.'),
                      ),
                    );
                  },
                  onRegisterPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeeklyChallengeRegistrationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'What participants receive',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 12),
                InfoBlock(
                  title: 'Career focus',
                  child: Text(
                    'Questions are aligned to the learner’s building areas (stack, role, projects) and go deeper than the daily mission.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text2For(context),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InfoBlock(
                  title: 'Guidance',
                  child: Text(
                    'Elite mentors provide feedback, suggested fixes, and scoring guidance after submission.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text2For(context),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InfoBlock(
                  title: 'Outcome',
                  child: Text(
                    'Earn a badge, share a write-up, and get visibility on moderator-curated leaderboards.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text2For(context),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

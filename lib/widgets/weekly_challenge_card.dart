import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/weekly_challenge_helpers.dart';
import 'app_ui_kit.dart';
import 'info_block.dart';

class WeeklyChallengeCard extends StatelessWidget {
  final dynamic user;
  final bool isEnrolled;
  final bool isLoading;
  final VoidCallback onDetailsPressed;
  final VoidCallback onRegisterPressed;

  const WeeklyChallengeCard({
    super.key,
    required this.user,
    this.isEnrolled = false,
    this.isLoading = false,
    required this.onDetailsPressed,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.indigo;
    final focusLabel = weeklyChallengeFocus(user);
    final roleLabel = weeklyChallengeSafeValue(user?.role, fallback: 'builder');

    return AppCard(
      color: accent.withValues(alpha: 0.08),
      border: Border.all(color: accent.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Coding Challenge',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid access for serious practice',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: 'RS 59 / USER',
                color: accent,
                icon: Icons.workspace_premium_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'A premium weekly challenge with one higher-signal coding task focused on your career path, target role, or future goal.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                label: roleLabel.toUpperCase(),
                color: Colors.orange,
                icon: Icons.person_pin_circle_rounded,
              ),
              AppBadge(
                label: focusLabel,
                color: accent,
                icon: Icons.track_changes_rounded,
              ),
              const AppBadge(
                label: 'CAREER-ALIGNED',
                color: Colors.green,
                icon: Icons.flag_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoBlock(
            title: 'WHAT USERS GET',
            child: Text(
              'Questions can be tailored around placements, internships, app development, AI/ML, backend work, or the kind of role the student wants to grow into.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.text2For(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isEnrolled)
            AppButton(
              onPressed: onDetailsPressed,
              backgroundColor: Colors.green,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enrolled - View Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
          else
            AppButton(
              onPressed: isLoading ? null : onRegisterPressed,
              backgroundColor: accent,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Register for challenge',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

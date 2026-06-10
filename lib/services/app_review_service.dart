import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class AppReviewService {
  AppReviewService._();
  static final instance = AppReviewService._();

  static const _keySessions = 'review_session_count';
  static const _keyLastPrompted = 'review_last_prompted_session';
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.devspace.community&pcampaignid=web_share';

  Future<void> logSession() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keySessions) ?? 0;
    await prefs.setInt(_keySessions, count + 1);
  }

  Future<void> checkAndShowPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keySessions) ?? 0;
    final lastPrompted = prefs.getInt(_keyLastPrompted) ?? 0;

    // Prompt after 5 sessions, and then every 10 sessions if they didn't review
    if (count >= 5 && (count - lastPrompted) >= 10) {
      if (context.mounted) {
        _showReviewDialog(context);
        await prefs.setInt(_keyLastPrompted, count);
      }
    }
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enjoying DevSpace?', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your feedback helps us build a better community for student developers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.amber, size: 32)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: TextStyle(color: AppColors.text3For(context))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final url = Uri.parse(_playStoreUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Rate on Play Store'),
          ),
        ],
      ),
    );
  }
}

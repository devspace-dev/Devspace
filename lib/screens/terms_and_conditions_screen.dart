import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(context),
        elevation: 0,
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textFor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Acceptance of Terms'),
            _sectionText(
              'By accessing or using DevSpace, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree, please do not use the application.',
            ),
            _sectionTitle('2. Eligibility'),
            _sectionText(
              'DevSpace is designed for college students and developers. You must provide accurate information during registration. Use of the app is restricted to individuals associated with an educational institution.',
            ),
            _sectionTitle('3. Content Responsibility'),
            _sectionText(
              'You are solely responsible for the content you post. DevSpace does not tolerate harassment, hate speech, or illegal content. We reserve the right to remove content or suspend accounts that violate these guidelines.',
            ),
            _sectionTitle('4. Privacy'),
            _sectionText(
              'Your privacy is important to us. We collect minimal data (email, name, profile details) to provide the service. We do not sell your data to third parties.',
            ),
            _sectionTitle('5. Intellectual Property'),
            _sectionText(
              'The app\'s design, logo, and code are the property of DevSpace. You retain ownership of the content you post but grant us a license to display it within the app.',
            ),
            _sectionTitle('6. Modifications'),
            _sectionText(
              'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: April 2026',
                style: TextStyle(
                  color: AppColors.text4For(context),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.text2,
      ),
    );
  }
}

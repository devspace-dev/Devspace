import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/premium_provider.dart';
import '../providers/auth_provider.dart';
import 'career_goal_onboarding_screen.dart';
import 'explore_premium_screen.dart';
import '../services/razorpay_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/info_block.dart';

class WeeklyChallengeRegistrationScreen extends StatefulWidget {
  const WeeklyChallengeRegistrationScreen({super.key});

  @override
  State<WeeklyChallengeRegistrationScreen> createState() =>
      _WeeklyChallengeRegistrationScreenState();
}

class _WeeklyChallengeRegistrationScreenState
    extends State<WeeklyChallengeRegistrationScreen> {
  bool _showPaymentSuccess = false;
  bool _isProcessingPayment = false;
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration(days: 2, hours: 14, minutes: 30);
  late RazorpayService _razorpayService;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.onPaymentSuccess = _handlePaymentSuccess;
    _razorpayService.onPaymentError = _handlePaymentError;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(dynamic response) async {
    if (!mounted) return;

    final premium = context.read<PremiumProvider>();
    final success = await premium.activatePremium();

    if (success) {
      setState(() {
        _showPaymentSuccess = true;
        _isProcessingPayment = false;
      });
      _startTimer();
    } else {
      setState(() => _isProcessingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment failed')),
        );
      }
    }
  }

  void _handlePaymentError(dynamic response) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment cancelled or failed.')),
    );
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft -= const Duration(seconds: 1);
        });
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  String _formatDuration(Duration d) {
    String days = d.inDays.toString().padLeft(2, '0');
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$days : $hours : $minutes : $seconds';
  }

  Future<void> _handlePayment() async {
    final user = context.read<AuthProvider>().currentUserOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found. Please login again.')),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    _razorpayService.openCheckout(
      amountInPaise: 4900,
      name: 'DevSpace',
      description: 'Weekly Coding Challenge',
      email: user.email,
      contact: '9876543210',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: Text(_showPaymentSuccess ? 'Registration Success' : 'Challenge Enrollment'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _showPaymentSuccess ? _buildSuccessView() : _buildEnrollmentView(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentView() {
    final accent = AppColors.indigo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium_rounded, size: 64, color: accent),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Weekly Coding Challenge',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sharpen your skills with industry-standard problems.',
          style: TextStyle(fontSize: 15, color: AppColors.text2For(context)),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('What you get'),
        const SizedBox(height: 12),
        _buildBulletPoint('Curated high-signal coding tasks'),
        _buildBulletPoint('Personalized Career Roadmap'),
        _buildBulletPoint('Skill Growth & Learning Strategy'),
        _buildBulletPoint('Elite feedback from industry mentors'),
        _buildBulletPoint('Verified Premium badge for profile'),
        _buildBulletPoint('Priority placement support'),
        const SizedBox(height: 24),
        _buildSectionTitle('Terms & Conditions'),
        const SizedBox(height: 12),
        InfoBlock(
          title: 'Honor Code',
          child: Text(
            'Participants must submit their own original work. Plagiarism will lead to disqualification and a negative aura impact.',
            style: TextStyle(fontSize: 13, color: AppColors.text3For(context), height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        InfoBlock(
          title: 'Refund Policy',
          child: Text(
            'Registration fee is non-refundable once the challenge window starts. Ensure you have a stable internet connection.',
            style: TextStyle(fontSize: 13, color: AppColors.text3For(context), height: 1.5),
          ),
        ),
        const SizedBox(height: 40),
        AppButton(
          onPressed: _handlePayment,
          isLoading: _isProcessingPayment,
          child: const Text('Enroll Now (₹49)'),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
        const SizedBox(height: 24),
        Text(
          'Registration Successful!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You are now enrolled in the Weekly Coding Challenge.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.text2For(context)),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bg2For(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            children: [
              Text(
                'CHALLENGE STARTS IN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.text3For(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDuration(_timeLeft),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'DAYS : HRS : MINS : SECS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text3For(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        InfoBlock(
          title: 'Important Date',
          child: Text(
            'Test Date: Sunday, 5 April 2026\nTime: 10:00 AM IST',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textFor(context),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 48),
        AppButton(
          onPressed: () {
            final premium = context.read<PremiumProvider>();
            if (!premium.careerGoalSelected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CareerGoalOnboardingScreen(isChanging: false)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExplorePremiumScreen()),
              );
            }
          },
          child: const Text('Continue to Premium'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textFor(context),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: AppColors.text2For(context)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/devspace_ui_helper.dart';
import '../models/user_model.dart';
import '../widgets/shareable_profile_card.dart';

class TierUpCelebrationScreen extends StatefulWidget {
  final UserModel user;
  final String tierName;

  const TierUpCelebrationScreen({
    super.key,
    required this.user,
    required this.tierName,
  });

  @override
  State<TierUpCelebrationScreen> createState() => _TierUpCelebrationScreenState();
}

class _TierUpCelebrationScreenState extends State<TierUpCelebrationScreen> {
  late Timer _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = TierHelper.getTier(widget.user.aura);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Background Glow Particles (Simulation)
            ...List.generate(20, (i) {
              return Positioned(
                left: (i * 50) % MediaQuery.of(context).size.width,
                top: (i * 100) % MediaQuery.of(context).size.height,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tier.accentColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat())
                 .moveY(begin: 0, end: -500, duration: (2000 + i * 100).ms)
                 .fadeOut(),
              );
            }),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large Bouncing Tier Icon
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tier.accentColor.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          tier.emoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 600.ms, curve: Curves.elasticOut)
                     .shimmer(delay: 1.seconds, duration: 2.seconds),

                    const SizedBox(height: 40),

                    Text(
                      "YOU'VE REACHED",
                      style: TextStyle(
                        color: tier.accentColor.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 8),

                    Text(
                      widget.tierName.toUpperCase(),
                      style: DevSpaceColors.headingStyle(
                        fontSize: 48,
                        color: tier.accentColor,
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 24),

                    const Text(
                      "Your Aura is growing. Keep building.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 60),

                    // Share Achievement Button
                    ShareableProfileCard(user: widget.user)
                        .animate()
                        .fadeIn(delay: 1.seconds)
                        .slideY(begin: 0.2),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      "Tap anywhere to dismiss",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ).animate().fadeIn(delay: 2.seconds),
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

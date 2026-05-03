import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/devspace_ui_helper.dart';

class AuraCardV2 extends StatelessWidget {
  final int auraPoints;

  const AuraCardV2({
    super.key,
    required this.auraPoints,
  });

  @override
  Widget build(BuildContext context) {
    final tier = TierHelper.getTier(auraPoints);
    final progress = TierHelper.getProgress(auraPoints);
    final pointsToNext = TierHelper.getPointsToNext(auraPoints);
    final nextTier = TierHelper.getNextTier(auraPoints);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DevSpaceColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier.accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Glowing Tier Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tier.accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut),
              
              const SizedBox(width: 20),
              
              // Tier Name & Aura Score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name.toUpperCase(),
                      style: DevSpaceColors.headingStyle(
                        fontSize: 20,
                        color: tier.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$auraPoints Aura',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 18),
          
          // Progress Bar
          Stack(
            children: [
              // Track
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              
              // Fill with Glow
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: DevSpaceColors.primary,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: DevSpaceColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat())
                 .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Muted Info Text
          if (nextTier != null)
            Text(
              '$pointsToNext pts to ${nextTier.name} tier',
              style: const TextStyle(
                color: DevSpaceColors.gray,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

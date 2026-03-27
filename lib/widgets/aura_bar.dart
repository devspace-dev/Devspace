import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../utils/aura_helpers.dart';
import '../theme/app_colors.dart';

class AuraBar extends StatelessWidget {
  final int aura;

  const AuraBar({super.key, required this.aura});

  @override
  Widget build(BuildContext context) {
    final badge    = getBadge(aura);
    final next     = getNextBadge(aura);
    final progress = getAuraProgress(aura);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badge.color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Text(
                '${badge.icon} ${badge.name}',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color: badge.color,
                ),
              ),
            ),
            Text(
              '${aura.toString()} AURA',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.text3, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.bg,
            valueColor: AlwaysStoppedAnimation<Color>(badge.color),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 8),
          Text(
            auraProgressLabel(aura).toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.text4, letterSpacing: 0.4),
          ),
        ],
      ],
    );
  }
}

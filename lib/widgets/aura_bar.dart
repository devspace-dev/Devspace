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
            Text(
              '${badge.icon} ${badge.name}',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: badge.color,
              ),
            ),
            Text(
              '${aura.toString()} Aura',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.bg3,
            valueColor: AlwaysStoppedAnimation<Color>(badge.color),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 6),
          Text(
            auraProgressLabel(aura),
            style: const TextStyle(fontSize: 11, color: AppColors.text3),
          ),
        ],
      ],
    );
  }
}

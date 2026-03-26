import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../theme/app_colors.dart';

class AuraPill extends StatelessWidget {
  final int aura;
  final bool small;

  const AuraPill({super.key, required this.aura, this.small = false});

  @override
  Widget build(BuildContext context) {
    final badge = getBadge(aura);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.icon,
            style: TextStyle(fontSize: small ? 10 : 12),
          ),
          const SizedBox(width: 4),
          Text(
            aura.toString(),
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

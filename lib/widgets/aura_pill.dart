import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: badge.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.icon,
            style: TextStyle(fontSize: small ? 12 : 14),
          ),
          const SizedBox(width: 6),
          Text(
            aura.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

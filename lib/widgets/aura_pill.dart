import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AuraPill extends StatelessWidget {
  final int aura;
  final bool small;

  const AuraPill({super.key, required this.aura, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⚡',
            style: TextStyle(fontSize: small ? 12 : 14),
          ),
          const SizedBox(width: 6),
          Text(
            '$aura Aura',
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

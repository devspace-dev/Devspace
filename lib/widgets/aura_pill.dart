import 'package:flutter/material.dart';
import '../models/badge_model.dart';

class AuraPill extends StatelessWidget {
  final int aura;
  final bool small;

  const AuraPill({super.key, required this.aura, this.small = false});

  @override
  Widget build(BuildContext context) {
    final badge = getBadge(aura);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${badge.icon} ${aura.toString()}',
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: badge.color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

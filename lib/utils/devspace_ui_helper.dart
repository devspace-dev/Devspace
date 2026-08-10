import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DevSpaceColors {
  static const Color primary = Color(0xFFB8FF57); // Lime Green
  static const Color background = Color(0xFF0A0A0F); // Ink Black
  static const Color surface = Color(0xFF12121A);
  static const Color gray = Color(0xFF888888);
  
  static TextStyle headingStyle({
    double fontSize = 24,
    Color color = Colors.white,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: color,
    );
  }
}

class TierInfo {
  final String name;
  final String emoji;
  final Color accentColor;
  final int minPoints;
  final int maxPoints;
  final String description;

  const TierInfo({
    required this.name,
    required this.emoji,
    required this.accentColor,
    required this.minPoints,
    required this.maxPoints,
    this.description = '',
  });
}

class TierHelper {
  static const List<TierInfo> tiers = [
    TierInfo(
      name: 'Aura',
      emoji: '⚡',
      accentColor: Color(0xFFB8FF57),
      minPoints: 0,
      maxPoints: 999999999,
      description: 'Developer Aura Points',
    ),
  ];

  static TierInfo getTier(int points) {
    return tiers.first;
  }

  static double getProgress(int points) {
    return 1.0;
  }

  static int getPointsToNext(int points) {
    return 0;
  }
  
  static TierInfo? getNextTier(int points) {
    return null;
  }
}

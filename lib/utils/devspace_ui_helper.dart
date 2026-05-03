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
      name: 'Seed',
      emoji: '🥚',
      accentColor: Color(0xFF9CA3AF),
      minPoints: 0,
      maxPoints: 149,
      description: 'Getting ready to sprout. Start contributing!',
    ),
    TierInfo(
      name: 'Sprout',
      emoji: '🌱',
      accentColor: Color(0xFF4ADE80),
      minPoints: 150,
      maxPoints: 999,
      description: 'You are just getting started. Keep building!',
    ),
    TierInfo(
      name: 'Spark',
      emoji: '⚡',
      accentColor: Color(0xFFFACC15),
      minPoints: 1000,
      maxPoints: 2499,
      description: 'The energy is building. Your code is catching fire.',
    ),
    TierInfo(
      name: 'Flame',
      emoji: '🔥',
      accentColor: Color(0xFFF97316),
      minPoints: 2500,
      maxPoints: 4999,
      description: 'You are on a roll. A true builder in the making.',
    ),
    TierInfo(
      name: 'Voltage',
      emoji: '🌀',
      accentColor: Color(0xFF22D3EE),
      minPoints: 5000,
      maxPoints: 9999,
      description: 'Incredible power. Your contributions are shocking.',
    ),
    TierInfo(
      name: 'Nova',
      emoji: '✨',
      accentColor: Color(0xFFB8FF57),
      minPoints: 10000,
      maxPoints: 999999999,
      description: 'A legendary builder. You are the star of DevSpace.',
    ),
  ];

  static TierInfo getTier(int points) {
    return tiers.firstWhere(
      (t) => points >= t.minPoints && points <= t.maxPoints,
      orElse: () => tiers.last,
    );
  }

  static double getProgress(int points) {
    final tier = getTier(points);
    if (tier.name == 'Nova') return 1.0;
    
    final range = tier.maxPoints - tier.minPoints + 1;
    final progress = points - tier.minPoints;
    return (progress / range).clamp(0.0, 1.0);
  }

  static int getPointsToNext(int points) {
    final tier = getTier(points);
    if (tier.name == 'Nova') return 0;
    return (tier.maxPoints + 1) - points;
  }
  
  static TierInfo? getNextTier(int points) {
    final current = getTier(points);
    final index = tiers.indexOf(current);
    if (index >= tiers.length - 1) return null;
    return tiers[index + 1];
  }
}

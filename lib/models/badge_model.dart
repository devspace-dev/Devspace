import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BadgeModel {
  final String name;
  final String icon;
  final Color color;
  final int min;
  final int max;
  final String description;

  const BadgeModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.description,
  });
}

const List<BadgeModel> kBadges = [
  BadgeModel(name: 'Seed',    icon: '🥚', color: Colors.grey,       min: 0,    max: 149,      description: 'Getting ready to sprout'),
  BadgeModel(name: 'Sprout',  icon: '🌱', color: AppColors.sprout,  min: 150,  max: 999,      description: 'Just getting started'),
  BadgeModel(name: 'Spark',   icon: '✨', color: AppColors.spark,   min: 1000, max: 1999,     description: 'Picking up momentum'),
  BadgeModel(name: 'Flame',   icon: '🔥', color: AppColors.flame,   min: 2000, max: 2999,     description: 'On fire — consistently active'),
  BadgeModel(name: 'Voltage', icon: '⚡', color: AppColors.voltage, min: 3000, max: 4999,     description: 'Top contributor in college'),
  BadgeModel(name: 'Nova',    icon: '🌟', color: AppColors.nova,    min: 5000, max: 999999999, description: 'Legendary status'),
];

BadgeModel getBadge(int aura) {
  return kBadges.lastWhere((b) => aura >= b.min, orElse: () => kBadges.first);
}

BadgeModel? getNextBadge(int aura) {
  try {
    return kBadges.firstWhere((b) => b.min > aura);
  } catch (_) {
    return null;
  }
}

double getAuraProgress(int aura) {
  final badge = getBadge(aura);
  final next  = getNextBadge(aura);
  if (next == null) return 1.0;
  return (aura - badge.min) / (badge.max - badge.min + 1);
}

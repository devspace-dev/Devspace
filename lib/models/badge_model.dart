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
  BadgeModel(
    name: 'Aura',
    icon: '⚡',
    color: AppColors.primary,
    min: 0,
    max: 999999999,
    description: 'Developer Aura Points',
  ),
];

BadgeModel getBadge(int aura) {
  return kBadges.first;
}

BadgeModel? getNextBadge(int aura) {
  return null;
}

double getAuraProgress(int aura) {
  return 1.0;
}

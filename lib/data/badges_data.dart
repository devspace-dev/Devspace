import 'package:flutter/material.dart';

class CommunityBadgeDefinition {
  final String key;
  final String name;
  final String icon;
  final String description;
  final String rule;
  final Color accentColor;

  const CommunityBadgeDefinition({
    required this.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.rule,
    this.accentColor = const Color(0xFFFFD54F),
  });
}

const List<CommunityBadgeDefinition> kCommunityBadges = [
  CommunityBadgeDefinition(
    key: 'first_practice_solve',
    name: 'First Practice Solve',
    icon: '🎯',
    description: 'Solved your first practice question.',
    rule: 'Solve 1 practice question in the Play tab.',
    accentColor: Color(0xFF64B5F6),
  ),
  CommunityBadgeDefinition(
    key: 'practice_easy_cleared',
    name: 'Easy Cleared',
    icon: '🌱',
    description: 'Cleared all 10 Easy practice questions.',
    rule: 'Solve all 10 Easy questions.',
    accentColor: Color(0xFF81C784),
  ),
  CommunityBadgeDefinition(
    key: 'practice_medium_cleared',
    name: 'Medium Cleared',
    icon: '⚔️',
    description: 'Cleared all 10 Medium practice questions.',
    rule: 'Solve all 10 Medium questions.',
    accentColor: Color(0xFFFFB74D),
  ),
  CommunityBadgeDefinition(
    key: 'practice_hard_cleared',
    name: 'Hard Cleared',
    icon: '🛡️',
    description: 'Cleared all 10 Hard practice questions.',
    rule: 'Solve all 10 Hard questions.',
    accentColor: Color(0xFFE57373),
  ),
  CommunityBadgeDefinition(
    key: 'practice_ultra_cleared',
    name: 'Ultra Cleared',
    icon: '👑',
    description: 'Cleared all 10 Ultra practice questions.',
    rule: 'Solve all 10 Ultra questions.',
    accentColor: Color(0xFFBA68C8),
  ),
  CommunityBadgeDefinition(
    key: 'streak_3_days',
    name: '3-Day Streak',
    icon: '🔥',
    description: 'Maintained a 3-day daily mission streak.',
    rule: 'Complete daily missions 3 days in a row.',
    accentColor: Color(0xFFFF8A65),
  ),
  CommunityBadgeDefinition(
    key: 'streak_7_days',
    name: '7-Day Streak',
    icon: '⚡',
    description: 'Maintained a 7-day daily mission streak.',
    rule: 'Complete daily missions 7 days in a row.',
    accentColor: Color(0xFFFFD54F),
  ),
  CommunityBadgeDefinition(
    key: 'first_duel_win',
    name: 'First Combat Win',
    icon: '🥊',
    description: 'Won your first Arena Combat duel.',
    rule: 'Win 1 Combat duel in Arena.',
    accentColor: Color(0xFF4DD0E1),
  ),
  CommunityBadgeDefinition(
    key: 'duel_winner_x10',
    name: 'Combat Veteran',
    icon: '🏆',
    description: 'Won 10 Arena Combat duels.',
    rule: 'Win 10 Combat duels in Arena.',
    accentColor: Color(0xFFFFD54F),
  ),
  CommunityBadgeDefinition(
    key: 'first_post',
    name: 'First Post',
    icon: '📝',
    description: 'Shared your first post with the community.',
    rule: 'Publish 1 post in the community feed.',
    accentColor: Color(0xFF64B5F6),
  ),
  CommunityBadgeDefinition(
    key: 'connector_x10',
    name: 'Connector',
    icon: '🤝',
    description: 'Connected with 10 fellow developers.',
    rule: 'Reach 10 followers in the community.',
    accentColor: Color(0xFFFFD54F),
  ),
];

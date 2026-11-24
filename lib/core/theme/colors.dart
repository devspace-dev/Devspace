import 'package:flutter/material.dart';

abstract class Ds {
  // Neutrals
  static const ink      = Color(0xFF0D0E14); // app background
  static const navBg    = Color(0xFF12131B);
  static const surface  = Color(0xFF181A24); // cards
  static const border   = Color(0xFF2C2F42);
  static const bone     = Color(0xFFF5F0E6); // primary text
  static const muted    = Color(0xFF9EA2B8); // secondary text

  // Hero: Aura
  static const aura     = Color(0xFFFFD23F);
  static const auraEdge = Color(0xFFB38F00); // bottom edge of yellow buttons
  static const onAura   = Color(0xFF14110A); // text/icons on yellow

  // Semantic
  static const mint      = Color(0xFF3DDC97); // correct, completed
  static const mintEdge  = Color(0xFF1F9C69);
  static const mintPanel = Color(0xFF12291F);
  static const hot       = Color(0xFFFF5A6E); // rival, streak, danger, mascot body

  // Rank tiers (Arena lobbies, leaderboard)
  static const tierBronze = Color(0xFFB07A4F); // Easy
  static const tierSilver = Color(0xFFAEB4BD); // Medium
  static const tierGold   = Color(0xFFE8B84A); // Hard
  static const tierGem    = Color(0xFF9C8CFF); // Ultra (use ONLY here)
}

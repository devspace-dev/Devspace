import 'package:flutter/material.dart';

class AppColors {
  // Midnight Pro (Pure Apple Style)
  static const primary   = Color(0xFF0A84FF); // Apple SF Blue (Vibrant Blue on Dark)
  static const secondary = Color(0xFF8E8E93); // System Gray
  static const blue      = Color(0xFF0A84FF);
  static const indigo    = Color(0xFF5E5CE6);
  static const purple    = Color(0xFFBF5AF2); // System Purple
  static const mint      = Color(0xFF63E6E2);

  // Background layers
  static const bg        = Color(0xFF000000); // Pure Black for OLED
  static const bg2       = Color(0xFF1C1C1E); // System Background Secondary
  static const bg3       = Color(0xFF2C2C2E); // System Background Tertiary

  // Borders & Dividers
  static const border    = Color(0xFF38383A); // Standard Separator
  static const border2   = Color(0xFF48484A); // Stronger Separator

  // Text
  static const text      = Color(0xFFFFFFFF); // Primary Text
  static const text2     = Color(0xFFEBEBF5); // Secondary Text (60% white)
  static const text3     = Color(0xFF8E8E93); // Tertiary Text (30% white)
  static const text4     = Color(0xFF48484A); // Quaternary Text

  // Aura badge colors (Refined iOS style)
  static const sprout    = Color(0xFF32D74B); // System Green
  static const spark     = Color(0xFFFFD60A); // System Yellow
  static const flame     = Color(0xFFFF453A); // System Red
  static const voltage   = Color(0xFFBF5AF2); // System Purple
  static const nova      = Color(0xFFFF375F); // System Pink

  // Semantic
  static const like      = Color(0xFFFF453A); // Heart Red
  static const repost    = Color(0xFF32D74B); // Success Green
  static const solved    = Color(0xFF32D74B);
  
  // Gradients (Subtle Apple-style)
  static const premiumGradient = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

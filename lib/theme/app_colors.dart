import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (Premium Warm Orange theme)
  static const primary   = Color(0xFFFF7A00); // DevSpace Premium Orange
  static const secondary = Color(0xFF8E8E93); // System Gray
  static const blue      = Color(0xFFFF7A00);
  static const indigo    = Color(0xFFFF5E00);
  static const purple    = Color(0xFFFF3D00); // Warm Accent Red-Orange
  static const mint      = Color(0xFFFFB000); // Warm Gold Accent

  // Aura badge colors (Warm Orange style)
  static const sprout    = Color(0xFF32D74B); // System Green
  static const spark     = Color(0xFFFFD60A); // System Yellow
  static const flame     = Color(0xFFFF453A); // System Red
  static const voltage   = Color(0xFFFF7A00); // Theme Orange
  static const nova      = Color(0xFFFF375F); // System Pink

  // Semantic
  static const like      = Color(0xFFFF453A); // Heart Red
  static const repost    = Color(0xFF32D74B); // Success Green
  static const solved    = Color(0xFF32D74B);

  // Backwards-compatible default palette used across the existing UI.
  static const bg        = Color(0xFF000000); // Pure OLED Black
  static const bg2       = Color(0xFF121214); // Sleek Surface Card
  static const bg3       = Color(0xFF1C1C1E); // Elevated Surface Card
  static const border    = Color(0xFF1F1F22); // Premium subtle border
  static const border2   = Color(0xFF2B2B30); // Focus/Active border
  static const text      = Color(0xFFFFFFFF); // Primary White
  static const text2     = Color(0xFFA1A1AA); // Secondary Muted Grey (zinc-400)
  static const text3     = Color(0xFF71717A); // Tertiary Muted (zinc-500)
  static const text4     = Color(0xFF52525B); // Quaternary Muted (zinc-600)

  // Dark Mode Colors
  static const bgDark        = Color(0xFF000000);
  static const bg2Dark       = Color(0xFF121214);
  static const bg3Dark       = Color(0xFF1C1C1E);
  static const borderDark    = Color(0xFF1F1F22);
  static const border2Dark   = Color(0xFF2B2B30);
  static const textDark      = Color(0xFFFFFFFF);
  static const text2Dark     = Color(0xFFA1A1AA);
  static const text3Dark     = Color(0xFF71717A);
  static const text4Dark     = Color(0xFF52525B);

  // Light Mode Colors
  static const bgLight        = Color(0xFFFFFFFF); // Clean white background
  static const bg2Light       = Color(0xFFF8F9FA); // Premium Card background
  static const bg3Light       = Color(0xFFF1F3F5); // Hover/Elevated Card background
  static const borderLight    = Color(0xFFE9ECEF); // Subtle light grey border
  static const border2Light   = Color(0xFFDEE2E6); // Focused border
  static const textLight      = Color(0xFF000000); // Main black text
  static const text2Light     = Color(0xFF343A40); // Secondary grey text
  static const text3Light     = Color(0xFF6C757D); // Muted tertiary text
  static const text4Light     = Color(0xFFADB5BD); // Light gray placeholder

  // Helper getters
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bgFor(BuildContext context) => isDark(context) ? bgDark : bgLight;
  static Color bg2For(BuildContext context) => isDark(context) ? bg2Dark : bg2Light;
  static Color bg3For(BuildContext context) => isDark(context) ? bg3Dark : bg3Light;
  static Color borderFor(BuildContext context) => isDark(context) ? borderDark : borderLight;
  static Color border2For(BuildContext context) => isDark(context) ? border2Dark : border2Light;
  static Color textFor(BuildContext context) => isDark(context) ? textDark : textLight;
  static Color text2For(BuildContext context) => isDark(context) ? text2Dark : text2Light;
  static Color text3For(BuildContext context) => isDark(context) ? text3Dark : text3Light;
  static Color text4For(BuildContext context) => isDark(context) ? text4Dark : text4Light;

  // Gradients
  static const premiumGradient = LinearGradient(
    colors: [Color(0xFFFF9E00), Color(0xFFFF5E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

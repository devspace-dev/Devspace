import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (Same for both usually, or slightly adjusted)
  static const primary   = Color(0xFF0A84FF); // Apple SF Blue
  static const secondary = Color(0xFF8E8E93); // System Gray
  static const blue      = Color(0xFF0A84FF);
  static const indigo    = Color(0xFF5E5CE6);
  static const purple    = Color(0xFFBF5AF2); // System Purple
  static const mint      = Color(0xFF63E6E2);

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

  // Backwards-compatible default palette used across the existing UI.
  static const bg        = Color(0xFF000000); // Pure Black for OLED
  static const bg2       = Color(0xFF1C1C1E); // System Background Secondary
  static const bg3       = Color(0xFF2C2C2E); // System Background Tertiary
  static const border    = Color(0xFF38383A); // Standard Separator
  static const border2   = Color(0xFF48484A); // Stronger Separator
  static const text      = Color(0xFFFFFFFF); // Primary Text
  static const text2     = Color(0xFFEBEBF5); // Secondary Text
  static const text3     = Color(0xFF8E8E93); // Tertiary Text
  static const text4     = Color(0xFF48484A); // Quaternary Text

  // Dark Mode Colors
  static const bgDark        = Color(0xFF000000); // Pure Black for OLED
  static const bg2Dark       = Color(0xFF1C1C1E); // System Background Secondary
  static const bg3Dark       = Color(0xFF2C2C2E); // System Background Tertiary
  static const borderDark    = Color(0xFF38383A); // Standard Separator
  static const border2Dark   = Color(0xFF48484A); // Stronger Separator
  static const textDark      = Color(0xFFFFFFFF); // Primary Text
  static const text2Dark     = Color(0xFFEBEBF5); // Secondary Text (60% white)
  static const text3Dark     = Color(0xFF8E8E93); // Tertiary Text (30% white)
  static const text4Dark     = Color(0xFF48484A); // Quaternary Text

  // Light Mode Colors
  static const bgLight        = Color(0xFFF2F2F7); // System Grouped Background
  static const bg2Light       = Color(0xFFFFFFFF); // Pure White
  static const bg3Light       = Color(0xFFE5E5EA); // System Background Tertiary
  static const borderLight    = Color(0xFFC6C6C8); // Standard Separator
  static const border2Light   = Color(0xFFAEAEB2); // Stronger Separator
  static const textLight      = Color(0xFF000000); // Primary Text
  static const text2Light     = Color(0xFF3C3C43); // Secondary Text (60% black)
  static const text3Light     = Color(0xFF8E8E93); // Tertiary Text (30% black)
  static const text4Light     = Color(0xFFC7C7CC); // Quaternary Text

  // Helper getters to use in widgets (though ThemeData is preferred)
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
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

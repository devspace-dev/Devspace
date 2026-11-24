import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class AppColors {
  // Primary colors (Unified Coin-Yellow Aura theme)
  static const primary   = Ds.aura;
  static const secondary = Ds.muted;
  static const blue      = Ds.aura;
  static const indigo    = Ds.aura;
  static const purple    = Ds.tierGem;
  static const mint      = Ds.mint;

  // Aura badge colors
  static const sprout    = Ds.mint;
  static const spark     = Ds.aura;
  static const flame     = Ds.hot;
  static const voltage   = Ds.aura;
  static const nova      = Ds.hot;

  // Semantic
  static const like      = Ds.hot;
  static const repost    = Ds.mint;
  static const solved    = Ds.mint;

  // Unified Dark Gaming Ground and Surfaces
  static const bg        = Ds.ink;
  static const bg2       = Ds.surface;
  static const bg3       = Color(0xFF1E212E);
  static const border    = Ds.border;
  static const border2   = Color(0xFF383C53);
  static const text      = Ds.bone;
  static const text2     = Ds.muted;
  static const text3     = Color(0xFF757A95);
  static const text4     = Color(0xFF555970);

  // Dark Mode Colors
  static const bgDark        = Ds.ink;
  static const bg2Dark       = Ds.surface;
  static const bg3Dark       = Color(0xFF1E212E);
  static const borderDark    = Ds.border;
  static const border2Dark   = Color(0xFF383C53);
  static const textDark      = Ds.bone;
  static const text2Dark     = Ds.muted;
  static const text3Dark     = Color(0xFF757A95);
  static const text4Dark     = Color(0xFF555970);

  // Light Mode Colors (In Glitch v1.0, dark mode is enforced; we map light getters to Ds dark tokens)
  static const bgLight        = Ds.ink;
  static const bg2Light       = Ds.surface;
  static const bg3Light       = Color(0xFF1E212E);
  static const borderLight    = Ds.border;
  static const border2Light   = Color(0xFF383C53);
  static const textLight      = Ds.bone;
  static const text2Light     = Ds.muted;
  static const text3Light     = Color(0xFF757A95);
  static const text4Light     = Color(0xFF555970);

  // Helper getters
  static bool isDark(BuildContext context) => true;

  static Color bgFor(BuildContext context) => Ds.ink;
  static Color bg2For(BuildContext context) => Ds.surface;
  static Color bg3For(BuildContext context) => const Color(0xFF1E212E);
  static Color borderFor(BuildContext context) => Ds.border;
  static Color border2For(BuildContext context) => const Color(0xFF383C53);
  static Color textFor(BuildContext context) => Ds.bone;
  static Color text2For(BuildContext context) => Ds.muted;
  static Color text3For(BuildContext context) => const Color(0xFF757A95);
  static Color text4For(BuildContext context) => const Color(0xFF555970);

  // Gradients
  static const premiumGradient = LinearGradient(
    colors: [Ds.aura, Ds.auraEdge],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

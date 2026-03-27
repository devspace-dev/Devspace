import 'package:flutter/material.dart';

class AppColors {
  // Tropical Punch Palette
  static const primary   = Color(0xFFFF3366); // Vibrant Strawberry
  static const secondary = Color(0xFF118AB2); // Deep Sea Blue
  static const orange    = Color(0xFFFF6B35); // Zesty Orange
  static const yellow    = Color(0xFFFFD23F); // Sunny Yellow
  static const mint      = Color(0xFF06D6A0); // Emerald Mint

  // Background layers (Deep Midnight / Plum)
  static const bg        = Color(0xFF0F0C1B); // Deep Midnight
  static const bg2       = Color(0xFF1B1731); // Deep Plum Surface
  static const bg3       = Color(0xFF252041); // Accent Surface

  // Borders
  static const border    = Color(0xFF352F5A); 
  static const border2   = Color(0xFF4A427F);

  // Text
  static const text      = Color(0xFFF8F7FF); // Bright Lavender/White
  static const text2     = Color(0xFFB8B2E0); // Soft Lavender
  static const text3     = Color(0xFF8A82B8); // Muted Purple
  static const text4     = Color(0xFF6A6298); // Dark Muted Purple

  // Aura badge colours (Tropical variants)
  static const sprout    = Color(0xFF06D6A0); // Mint
  static const spark     = Color(0xFFFFD23F); // Yellow
  static const flame     = Color(0xFFFF6B35); // Orange
  static const voltage   = Color(0xFFFF3366); // Strawberry
  static const nova      = Color(0xFF118AB2); // Blue

  // Semantic
  static const like      = Color(0xFFFF3366);
  static const repost    = Color(0xFF06D6A0);
  static const solved    = Color(0xFF06D6A0);
  
  // Gradients
  static const tropicalGradient = LinearGradient(
    colors: [primary, orange, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

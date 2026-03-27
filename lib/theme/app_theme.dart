import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.secondary,
        surface:   AppColors.bg2,
        onSurface: AppColors.text,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.text3,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800, 
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
    );
  }
}

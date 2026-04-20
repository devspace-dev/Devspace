import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'devspace_page_transitions.dart';

class AppTheme {
  static ThemeData get dark {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData get light {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final bg2Color = isDark ? AppColors.bg2Dark : AppColors.bg2Light;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.flame,
        onError: Colors.white,
        surface: bg2Color,
        onSurface: textColor,
      ),
      textTheme: _buildScaledTextTheme(GoogleFonts.interTextTheme(baseTheme.textTheme), textColor, 0.9),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.primary, size: 24),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg2Color.withValues(alpha: 0.8),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.text3Dark : AppColors.text3Light,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DevSpacePageTransitionsBuilder(),
          TargetPlatform.iOS: DevSpacePageTransitionsBuilder(),
          TargetPlatform.macOS: DevSpacePageTransitionsBuilder(),
          TargetPlatform.windows: DevSpacePageTransitionsBuilder(),
          TargetPlatform.linux: DevSpacePageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: 0.6),
        thickness: 0.8,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg2Color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.text3Dark : AppColors.text3Light,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black, // High contrast black on Electric Azure
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: bg2Color,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1),
        ),
      ),
    );
  }

  static TextTheme _buildScaledTextTheme(TextTheme base, Color textColor, double factor) {
    // We apply colors first. .apply() is safe with null fontSizes if factor is 1.0.
    final coloredTheme = base.apply(bodyColor: textColor, displayColor: textColor);
    
    // Then we manually scale the styles that are most commonly used and guaranteed to have sizes from GoogleFonts
    return coloredTheme.copyWith(
      displayLarge: coloredTheme.displayLarge?.copyWith(fontSize: (coloredTheme.displayLarge?.fontSize ?? 57) * factor),
      displayMedium: coloredTheme.displayMedium?.copyWith(fontSize: (coloredTheme.displayMedium?.fontSize ?? 45) * factor),
      displaySmall: coloredTheme.displaySmall?.copyWith(fontSize: (coloredTheme.displaySmall?.fontSize ?? 36) * factor),
      headlineLarge: coloredTheme.headlineLarge?.copyWith(fontSize: (coloredTheme.headlineLarge?.fontSize ?? 32) * factor),
      headlineMedium: coloredTheme.headlineMedium?.copyWith(fontSize: (coloredTheme.headlineMedium?.fontSize ?? 28) * factor),
      headlineSmall: coloredTheme.headlineSmall?.copyWith(fontSize: (coloredTheme.headlineSmall?.fontSize ?? 24) * factor),
      titleLarge: coloredTheme.titleLarge?.copyWith(fontSize: (coloredTheme.titleLarge?.fontSize ?? 22) * factor),
      titleMedium: coloredTheme.titleMedium?.copyWith(fontSize: (coloredTheme.titleMedium?.fontSize ?? 16) * factor),
      titleSmall: coloredTheme.titleSmall?.copyWith(fontSize: (coloredTheme.titleSmall?.fontSize ?? 14) * factor),
      bodyLarge: coloredTheme.bodyLarge?.copyWith(fontSize: (coloredTheme.bodyLarge?.fontSize ?? 16) * factor),
      bodyMedium: coloredTheme.bodyMedium?.copyWith(fontSize: (coloredTheme.bodyMedium?.fontSize ?? 14) * factor),
      bodySmall: coloredTheme.bodySmall?.copyWith(fontSize: (coloredTheme.bodySmall?.fontSize ?? 12) * factor),
      labelLarge: coloredTheme.labelLarge?.copyWith(fontSize: (coloredTheme.labelLarge?.fontSize ?? 14) * factor),
      labelMedium: coloredTheme.labelMedium?.copyWith(fontSize: (coloredTheme.labelMedium?.fontSize ?? 12) * factor),
      labelSmall: coloredTheme.labelSmall?.copyWith(fontSize: (coloredTheme.labelSmall?.fontSize ?? 11) * factor),
    );
  }
}

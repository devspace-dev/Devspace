import 'package:flutter/material.dart';
import 'colors.dart';
import 'text.dart';

ThemeData buildTheme() {
  final scheme = const ColorScheme.dark(
    primary: Ds.aura,
    onPrimary: Ds.onAura,
    secondary: Ds.hot,
    onSecondary: Ds.ink,
    tertiary: Ds.mint,
    onTertiary: Ds.ink,
    surface: Ds.surface,
    onSurface: Ds.bone,
    error: Ds.hot,
    onError: Ds.ink,
    outline: Ds.border,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Ds.ink,
    canvasColor: Ds.ink,
    dividerColor: Ds.border,
    splashFactory: NoSplash.splashFactory, // we use press-down animation instead
    textTheme: TextTheme(
      displayLarge: DsText.display,
      headlineLarge: DsText.h1,
      headlineMedium: DsText.h2,
      titleLarge: DsText.h3,
      bodyLarge: DsText.body,
      bodyMedium: DsText.bodySm,
      labelLarge: DsText.label,
      labelSmall: DsText.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Ds.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

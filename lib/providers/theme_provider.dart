import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => ThemeMode.dark;

  ThemeProvider({ThemeMode? initialMode}) : _themeMode = ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }
}

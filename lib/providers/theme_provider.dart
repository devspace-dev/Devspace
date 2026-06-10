import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider({ThemeMode? initialMode}) : _themeMode = initialMode ?? ThemeMode.system {
    _loadTheme();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode');
    if (modeStr != null) {
      final loadedMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == modeStr,
        orElse: () => ThemeMode.system,
      );
      if (loadedMode != _themeMode) {
        _themeMode = loadedMode;
        notifyListeners();
      }
    }
  }
}

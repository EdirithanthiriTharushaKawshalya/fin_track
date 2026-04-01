import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'user_theme_mode';

  // Save selection to disk
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  // Retrieve selection from disk
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeName = prefs.getString(_themeKey);
    
    if (themeName == null) return ThemeMode.dark; // Default
    return ThemeMode.values.firstWhere((e) => e.name == themeName);
  }
}
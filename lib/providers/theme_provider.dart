import 'package:flutter/material.dart';

import '../services/config_service.dart';

/// ThemeProvider - Manages app theme (light/dark mode)
class ThemeProvider extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadThemeFromConfig();
  }

  /// Load theme setting from config
  Future<void> _loadThemeFromConfig() async {
    try {
      final theme = await _configService.getTheme();
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _isLoading = false;
      notifyListeners();
      print('🎨 [THEME_PROVIDER] Theme loaded: $theme');
    } catch (e) {
      print('❌ [THEME_PROVIDER] Error loading theme: $e');
      _themeMode = ThemeMode.light;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    final themeString = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _configService.update('theme', themeString);

    notifyListeners();
    print('🎨 [THEME_PROVIDER] Theme changed to: $themeString');
  }

  /// Set theme explicitly
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    final themeString = mode == ThemeMode.dark ? 'dark' : 'light';
    await _configService.update('theme', themeString);

    notifyListeners();
    print('🎨 [THEME_PROVIDER] Theme set to: $themeString');
  }

  /// Set dark mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    await setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

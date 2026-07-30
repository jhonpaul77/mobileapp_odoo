// lib/services/status_bar_service.dart

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class StatusBarService {
  /// Set status bar untuk halaman terang (background putih/terang)
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Icon gelap
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Set status bar untuk halaman gelap (background biru/warna)
  static void setDarkStatusBar({Color statusBarColor = Colors.transparent}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: Brightness.light, // Icon putih
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Set status bar dengan warna theme
  static void setThemeStatusBar(Color bgColor, Color? statusBarColor) {
    // Tentukan brightness berdasarkan color luminance
    final brightness = bgColor.computeLuminance() > 0.5
        ? Brightness.dark // Background terang → icon gelap
        : Brightness.light; // Background gelap → icon putih

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: brightness,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}

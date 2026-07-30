// lib/pages/home/utils/constants.dart

import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';

class AppConstants {
  // Border Radius
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Icon Sizes
  static const double iconSmall = 18.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

class AppColors {
  // Menggunakan colors dari theme.dart
  static const Color primaryColor = AppTheme.primaryColor;
  static const Color secondaryColor = AppTheme.secondaryColor;

  // Status Colors
  static const Color successColor = AppTheme.successColor;
  static const Color dangerColor = AppTheme.errorColor;
  static const Color warningColor = AppTheme.warningColor;
  static const Color infoColor = AppTheme.infoColor;

  // Specific Colors untuk Dashboard
  static const Color salesColor = Color(0xFF4A90E2); // Blue
  static const Color inventoryColor = Color(0xFF9575CD); // Purple
  static const Color productionColor = Color(0xFF00BCD4); // Cyan
  static const Color expenseColor = Color(0xFFE57373); // Red
}

import 'package:flutter/material.dart';

/// Couleurs de marque AURAGOAL — bleu / cyan / violet.
/// À ajuster une fois la charte graphique définitive validée.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF2E5CFF);
  static const Color accentCyan = Color(0xFF00D2FF);
  static const Color accentViolet = Color(0xFF7B5CFF);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE74C3C);

  static const Color darkBackground = Color(0xFF0E0F1A);
  static const Color lightBackground = Color(0xFFF7F8FC);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.accentViolet,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.accentViolet,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

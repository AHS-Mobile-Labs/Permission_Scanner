import 'package:flutter/material.dart';

/// Centralized color configuration for the entire app.
/// This file serves as the single source of truth for all colors used in the application.
class AppColorConfig {
  // Primary palette - green accent
  static const Color primaryMain = Color(0xFF0E7B72);
  static const Color primaryDark = Color(0xFF0A5D56);
  static const Color primaryLight = Color(0xFF95CBC5);
  static const Color primaryContainer = Color(0xFFCCFBF1);

  static const Color secondary = Color(0xFF95CBC5);
  static const Color secondaryContainer = Color(0xFFE0F2FE);

  // Surfaces
  static const Color background = Color(0xFFF8FAFB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);

  // Semantic risk colors
  static const Color riskSafe = Color(0xFF16A34A);
  static const Color riskSafeContainer = Color(0xFFDCFCE7);
  static const Color riskMedium = Color(0xFFF59E0B);
  static const Color riskMediumContainer = Color(0xFFFEF3C7);
  static const Color riskDangerous = Color(0xFFDC2626);
  static const Color riskDangerousContainer = Color(0xFFFEE2E2);
  static const Color riskCritical = Color(0xFF7F1D1D);
  static const Color riskCriticalContainer = Color(0xFFFECACA);

  // Dividers & borders
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF0A5D56), // Dark
    Color(0xFF0E7B72), // Main
    Color(0xFF95CBC5), // Light
  ];

  static const List<Color> dashboardGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
  ];

  /// Get RGB values for Python/image generation (returns (R, G, B) tuple)
  static Map<String, dynamic> toExportFormat() {
    return {
      'primary_main': '#0E7B72',
      'primary_dark': '#0A5D56',
      'primary_light': '#95CBC5',
      'secondary': '#95CBC5',
      'background': '#F8FAFB',
      'text_dark': '#0F172A',
      'text_medium': '#475569',
      'text_light': '#94A3B8',
      'risk_safe': '#16A34A',
      'risk_medium': '#F59E0B',
      'risk_dangerous': '#DC2626',
      'risk_critical': '#7F1D1D',
    };
  }
}

/// Alias for backward compatibility with existing code
class AppColors {
  static const Color primary = AppColorConfig.primaryMain;
  static const Color primaryContainer = AppColorConfig.primaryContainer;
  static const Color secondary = AppColorConfig.secondary;
  static const Color secondaryContainer = AppColorConfig.secondaryContainer;
  static const Color background = AppColorConfig.background;
  static const Color cardBackground = AppColorConfig.cardBackground;
  static const Color surfaceVariant = AppColorConfig.surfaceVariant;
  static const Color textDark = AppColorConfig.textDark;
  static const Color textMedium = AppColorConfig.textMedium;
  static const Color textLight = AppColorConfig.textLight;
  static const Color riskSafe = AppColorConfig.riskSafe;
  static const Color riskSafeContainer = AppColorConfig.riskSafeContainer;
  static const Color riskMedium = AppColorConfig.riskMedium;
  static const Color riskMediumContainer = AppColorConfig.riskMediumContainer;
  static const Color riskDangerous = AppColorConfig.riskDangerous;
  static const Color riskDangerousContainer =
      AppColorConfig.riskDangerousContainer;
  static const Color riskCritical = AppColorConfig.riskCritical;
  static const Color riskCriticalContainer =
      AppColorConfig.riskCriticalContainer;
  static const Color divider = AppColorConfig.divider;
  static const Color border = AppColorConfig.border;
  static const List<Color> primaryGradient = AppColorConfig.primaryGradient;
  static const List<Color> dashboardGradient = AppColorConfig.dashboardGradient;
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.cardBackground,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onPrimary: Colors.white,
        onSurface: AppColors.textDark,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(AppColors.surfaceVariant),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
        hintStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
      ),
    );
  }
}

// lib/core/theme/senior_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

class SeniorTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pillDeep,
        brightness: Brightness.light,
        background: AppColors.bg,
      ),
      fontFamily: 'Pretendard',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: AppSizes.bodyFontSize, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: AppSizes.bodyFontSize, color: AppColors.ink),
        titleLarge: TextStyle(fontSize: AppSizes.titleFontSize, fontWeight: FontWeight.w800, color: AppColors.ink),
        labelLarge: TextStyle(fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minButtonHeight),
          backgroundColor: AppColors.pillDeep,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// lib/core/theme/caregiver_theme.dart
import 'package:flutter/material.dart';
import 'tokens.dart';

class CaregiverTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.caregiverBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.caregiverPrimary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Pretendard',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: AppSizes.caregiverBodyFontSize),
        bodyMedium: TextStyle(fontSize: AppSizes.caregiverBodyFontSize),
        labelLarge: TextStyle(fontSize: AppSizes.caregiverButtonFontSize, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.caregiverMinButtonHeight),
          backgroundColor: AppColors.caregiverPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

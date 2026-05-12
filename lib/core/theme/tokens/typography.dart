// lib/core/theme/tokens/typography.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'sizes.dart';

/// 부모(어르신) TextTheme — 큰 글씨, 무거운 weight.
class SeniorTypography {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppSizes.displayFontSize, fontWeight: FontWeight.w800,
      color: AppColors.ink, letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: AppSizes.titleFontSize, fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: AppSizes.bodyFontSize, color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: AppSizes.bodyDenseFontSize, color: AppColors.ink,
    ),
    labelLarge: TextStyle(
      fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700,
    ),
    labelMedium: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6,
      color: AppColors.inkMute,
    ),
    bodySmall: TextStyle(
      fontSize: 14, color: AppColors.ink2,
    ),
  );
}

/// 자녀(보호자) TextTheme — 표준 사이즈, 가벼운 weight.
class CaregiverTypography {
  static const TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: AppSizes.caregiverTitleFontSize, fontWeight: FontWeight.w700,
      color: AppColors.caregiverInk,
    ),
    titleMedium: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: AppColors.caregiverInk,
    ),
    bodyLarge: TextStyle(
      fontSize: AppSizes.caregiverBodyFontSize, color: AppColors.caregiverInk,
    ),
    bodyMedium: TextStyle(
      fontSize: AppSizes.caregiverBodyFontSize, color: AppColors.caregiverInk,
    ),
    labelLarge: TextStyle(
      fontSize: AppSizes.caregiverButtonFontSize, fontWeight: FontWeight.w600,
    ),
    bodySmall: TextStyle(
      fontSize: 13, color: AppColors.caregiverInkMute,
    ),
  );
}

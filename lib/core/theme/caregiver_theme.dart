// lib/core/theme/caregiver_theme.dart
import 'package:flutter/material.dart';
import 'semantic_colors.dart';
import 'tokens.dart';

class CaregiverTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.caregiverPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.caregiverPrimary,
      onPrimary: Colors.white,
      surface: AppColors.caregiverCard,
      onSurface: AppColors.caregiverInk,
      error: AppColors.caregiverDanger,
      outline: AppColors.caregiverBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.caregiverBg,
      fontFamily: 'Pretendard',
      extensions: const [AppSemanticColors.caregiver],

      textTheme: CaregiverTypography.textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.caregiverCard,
        foregroundColor: AppColors.caregiverInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.caregiverInk,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.caregiverCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        shadowColor: Color(0x14000000),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.caregiverMinButtonHeight),
          backgroundColor: AppColors.caregiverPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: AppSizes.caregiverButtonFontSize,
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.caregiverMinButtonHeight),
          foregroundColor: AppColors.caregiverPrimary,
          side: const BorderSide(color: AppColors.caregiverPrimary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.caregiverSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll, borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll, borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.caregiverPrimary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(color: AppColors.caregiverInkMute, fontSize: 15),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.caregiverBorder,
        thickness: 1, space: AppSpacing.xxl,
      ),

      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: 'Pretendard', fontSize: 12, fontWeight: FontWeight.w600,
          color: Colors.white, letterSpacing: 0.3,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.caregiverCard,
        indicatorColor: AppColors.caregiverPrimary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.caregiverInk,
        )),
        height: 64,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.caregiverCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}

// lib/core/theme/senior_theme.dart
import 'package:flutter/material.dart';
import 'semantic_colors.dart';
import 'tokens.dart';

class SeniorTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pillDeep,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.pillDeep,
      onPrimary: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.care,
      outline: AppColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Pretendard',
      extensions: const [AppSemanticColors.senior],

      textTheme: SeniorTypography.textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        shadowColor: Color(0x14000000),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minButtonHeight),
          backgroundColor: AppColors.pillDeep,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minButtonHeight),
          foregroundColor: AppColors.pillDeep,
          side: const BorderSide(color: AppColors.pillDeep, width: 1.5),
          textStyle: const TextStyle(
            fontSize: AppSizes.buttonFontSize, fontWeight: FontWeight.w700,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pillDeep,
          textStyle: const TextStyle(
            fontSize: AppSizes.bodyFontSize, fontWeight: FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minButtonHeight),
          backgroundColor: AppColors.pillDeep,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper2,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: AppColors.pillDeep, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md,
        ),
        hintStyle: TextStyle(color: AppColors.inkMute, fontSize: AppSizes.bodyFontSize),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: AppSpacing.xxl,
      ),

      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: 'Pretendard', fontSize: 13, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: 0.4,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.pillDeep.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.pillDeep : AppColors.ink2,
            size: 28,
          );
        }),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
    );
  }
}

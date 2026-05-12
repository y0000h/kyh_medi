// lib/core/theme/semantic_colors.dart
import 'package:flutter/material.dart';
import 'tokens/colors.dart';

/// Material `ColorScheme`에 자리가 없는 의미색을 테마에 얹기 위한 ThemeExtension.
/// `success` / `danger` / `warning` / `border` / `ink2` / `inkMute`.
///
/// 사용: `Theme.of(context).extension<AppSemanticColors>()!.success`
///       또는 편의 헬퍼 `AppSemanticColors.of(context).success`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color danger;
  final Color warning;
  final Color border;
  final Color ink2;
  final Color inkMute;

  const AppSemanticColors({
    required this.success,
    required this.danger,
    required this.warning,
    required this.border,
    required this.ink2,
    required this.inkMute,
  });

  /// 부모(어르신) 팔레트 매핑.
  static const senior = AppSemanticColors(
    success: AppColors.jade,
    danger: AppColors.care,
    warning: AppColors.capsule,
    border: AppColors.line,
    ink2: AppColors.ink2,
    inkMute: AppColors.inkMute,
  );

  /// 자녀(보호자) 팔레트 매핑.
  static const caregiver = AppSemanticColors(
    success: AppColors.caregiverSuccess,
    danger: AppColors.caregiverDanger,
    warning: AppColors.caregiverWarning,
    border: AppColors.caregiverBorder,
    ink2: AppColors.caregiverInk2,
    inkMute: AppColors.caregiverInkMute,
  );

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? senior;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? danger,
    Color? warning,
    Color? border,
    Color? ink2,
    Color? inkMute,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      ink2: ink2 ?? this.ink2,
      inkMute: inkMute ?? this.inkMute,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      inkMute: Color.lerp(inkMute, other.inkMute, t)!,
    );
  }
}

// lib/core/theme/tokens/sizes.dart
import 'spacing.dart';

/// 모드별 사이즈 토큰. 부모는 어르신 가독성 우선(큼), 자녀는 표준.
class AppSizes {
  // 부모
  static const double bodyFontSize = 18.0;
  static const double bodyDenseFontSize = 16.0;
  static const double buttonFontSize = 18.0;
  static const double titleFontSize = 24.0;
  static const double displayFontSize = 32.0;
  static const double minButtonHeight = 56.0;
  static const double largeButtonHeight = 80.0;
  static const double padding = AppSpacing.xl;

  // 자녀
  static const double caregiverBodyFontSize = 15.0;
  static const double caregiverButtonFontSize = 15.0;
  static const double caregiverTitleFontSize = 24.0;
  static const double caregiverMinButtonHeight = 48.0;
}

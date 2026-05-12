// lib/core/theme/tokens.dart
//
// 토큰 barrel — 기존 import 경로(`import '...theme/tokens.dart'`)를 유지하면서
// 내부적으로는 `tokens/` 폴더로 분할된 파일들을 합쳐 노출.
//
//   AppColors        → tokens/colors.dart
//   AppSpacing       → tokens/spacing.dart
//   AppRadius        → tokens/radius.dart
//   AppShadows       → tokens/shadows.dart
//   AppSizes         → tokens/sizes.dart
//   Senior/CaregiverTypography → tokens/typography.dart
//
// 의미색(success/danger/warning/border/ink2/inkMute)은
// `semantic_colors.dart`의 `AppSemanticColors` ThemeExtension에서 꺼낸다.

export 'tokens/colors.dart';
export 'tokens/spacing.dart';
export 'tokens/radius.dart';
export 'tokens/shadows.dart';
export 'tokens/sizes.dart';
export 'tokens/typography.dart';

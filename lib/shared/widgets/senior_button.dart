// lib/shared/widgets/senior_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';

/// 부모(어르신) 모드 기본 버튼. `variant`로 의미를 표현.
///
/// - `primary` (기본): 채워진 brand 버튼.
/// - `secondary`: outlined brand 버튼. "주된 액션이 아닌" 보조 흐름용.
/// - `success`: 채워진 success 버튼. "복용 완료" 같은 긍정 확정 액션용.
/// - `destructive`: 채워진 danger 버튼. 삭제/취소 등 되돌릴 수 없는 동작용.
///
/// `large: true`면 80px 영웅 사이즈(온보딩의 "알림 받기 시작" 같은 곳).
enum SeniorButtonVariant { primary, secondary, success, destructive }

class SeniorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SeniorButtonVariant variant;
  final bool large;

  const SeniorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SeniorButtonVariant.primary,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = large ? AppSizes.largeButtonHeight : AppSizes.minButtonHeight;
    final textStyle = TextStyle(
      fontSize: large ? 26 : AppSizes.buttonFontSize,
      fontWeight: FontWeight.w700,
    );

    final child = SizedBox(
      width: double.infinity,
      height: height,
      child: _buildButton(context, textStyle),
    );
    return child;
  }

  Widget _buildButton(BuildContext context, TextStyle textStyle) {
    switch (variant) {
      case SeniorButtonVariant.primary:
        return ElevatedButton(
          onPressed: onPressed,
          child: Text(label, style: textStyle),
        );
      case SeniorButtonVariant.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          child: Text(label, style: textStyle),
        );
      case SeniorButtonVariant.success:
        final success = AppSemanticColors.of(context).success;
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: success,
            foregroundColor: Colors.white,
          ),
          child: Text(label, style: textStyle),
        );
      case SeniorButtonVariant.destructive:
        final danger = AppSemanticColors.of(context).danger;
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: Colors.white,
          ),
          child: Text(label, style: textStyle),
        );
    }
  }
}

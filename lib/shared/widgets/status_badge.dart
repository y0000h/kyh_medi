// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../../core/theme/semantic_colors.dart';
import '../../core/theme/tokens.dart';

enum StatusKind { success, danger, warning, info }

/// Pill 모양 상태 뱃지 — "복용 완료" / "미복용" / "복용 전" 등.
/// 시니어/보호자 모드에서 동일 사용. 색은 활성 테마의 `AppSemanticColors`에서 자동 분기.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusKind kind;

  const StatusBadge({
    super.key,
    required this.label,
    required this.kind,
  });

  Color _bgFor(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    switch (kind) {
      case StatusKind.success:
        return semantic.success;
      case StatusKind.danger:
        return semantic.danger;
      case StatusKind.warning:
        return semantic.warning;
      case StatusKind.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: _bgFor(context),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'NanumSquare',
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

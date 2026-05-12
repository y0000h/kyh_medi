// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum StatusKind { success, danger, warning, info }

/// Pill 모양 상태 뱃지 — "복용 완료" / "미복용" / "복용 전" 등.
/// 시니어 모드 / 보호자 모드 양쪽에서 동일 사용. 색은 ColorScheme + AppColors 기반.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusKind kind;

  const StatusBadge({
    super.key,
    required this.label,
    required this.kind,
  });

  Color _bgFor(BuildContext context) {
    final isCaregiver = Theme.of(context).colorScheme.primary == AppColors.caregiverPrimary;
    switch (kind) {
      case StatusKind.success:
        return isCaregiver ? AppColors.caregiverSuccess : AppColors.jade;
      case StatusKind.danger:
        return isCaregiver ? AppColors.caregiverDanger : AppColors.care;
      case StatusKind.warning:
        return isCaregiver ? AppColors.caregiverWarning : AppColors.capsule;
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
          fontFamily: 'Pretendard',
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

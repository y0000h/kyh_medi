// lib/shared/widgets/section_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// `Card + InkWell + Padding` 보일러플레이트를 캡슐화한 primitive.
/// 리스트 아이템, 설정 행, 홈 카드 등에서 반복되는 패턴을 한 줄로.
///
/// - `onTap`이 있으면 InkWell 래핑(파동 효과 + tap 영역 = 카드 전체).
/// - 기본 padding은 spec 권장 `xl`(20). 좁게 쓰고 싶으면 `padding` 오버라이드.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? const EdgeInsets.all(AppSpacing.xl);
    final inner = onTap == null
        ? Padding(padding: pad, child: child)
        : InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Padding(padding: pad, child: child),
          );

    final card = Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
    return card;
  }
}

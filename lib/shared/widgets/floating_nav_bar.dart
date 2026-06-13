// lib/shared/widgets/floating_nav_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

/// 레퍼런스(LILOO)식 "떠 있는 알약형" 하단 탭바.
///
/// - 둥근(pill) 반투명 글래스 컨테이너가 화면 하단에서 살짝 떠 있다.
/// - 선택된 탭은 액센트(피치/연두) 원형 칩 안에 아이콘이 들어간다.
/// - 아이콘 아래 작은 라벨(어르신 가독성 유지). 선택 시 라벨도 액센트 색.
class FloatingNavItem {
  final IconData icon;
  final String label;
  const FloatingNavItem(this.icon, this.label);
}

class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final onAccent = cs.onPrimary;
    final muted = cs.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.78),
                borderRadius: AppRadius.pillAll,
                border: Border.all(color: cs.outline, width: 1),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 8), blurRadius: 24, color: Color(0x40000000),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (i) {
                  final selected = i == currentIndex;
                  return Expanded(
                    child: _NavCell(
                      item: items[i],
                      selected: selected,
                      accent: accent,
                      onAccent: onAccent,
                      muted: muted,
                      onTap: () => onTap(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final Color accent;
  final Color onAccent;
  final Color muted;
  final VoidCallback onTap;

  const _NavCell({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onAccent,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: selected ? onAccent : muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'NanumSquare',
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? accent : muted,
            ),
          ),
        ],
      ),
    );
  }
}

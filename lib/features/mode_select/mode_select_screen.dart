// lib/features/mode_select/mode_select_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/hive/hive_init.dart';
import '../../core/theme/tokens.dart';
import '../parent/settings/data/settings_repository.dart';
import '../parent/settings/domain/app_settings.dart';

class ModeSelectScreen extends StatelessWidget {
  final void Function(String mode) onSelected;
  const ModeSelectScreen({super.key, required this.onSelected});

  Future<void> _select(BuildContext context, String mode) async {
    final box = Hive.box<AppSettings>(HiveInit.settingsBox);
    await SettingsRepository(box).setUserMode(mode);
    onSelected(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.seniorBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // 히어로 글로우 그래픽
                const _HeroGlyph(),
                const SizedBox(height: 36),
                const Text('한 알도,\n잊지 않게',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800,
                      color: AppColors.ink, height: 1.15, letterSpacing: -0.5,
                    )),
                const SizedBox(height: 12),
                const Text('어떻게 사용하시나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: AppColors.ink2)),
                const Spacer(),
                // 부모 — 채워진 피치 카드
                _ModeCard(
                  title: '부모님이세요?',
                  subtitle: '내가 약 먹을 시간을 알려주세요',
                  icon: Icons.elderly_rounded,
                  filled: true,
                  onTap: () => _select(context, AppSettings.modeParent),
                ),
                const SizedBox(height: 16),
                // 자녀 — 글래스 카드
                _ModeCard(
                  title: '자녀세요?',
                  subtitle: '부모님 복용 상태를 확인하고 싶어요',
                  icon: Icons.favorite_rounded,
                  filled: false,
                  onTap: () => _select(context, AppSettings.modeChild),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 레퍼런스의 플로잉 라인아트를 대신하는 부드러운 글로우 + 알약 글리프.
class _HeroGlyph extends StatelessWidget {
  const _HeroGlyph();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180, height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x553D7BF5), Color(0x003D7BF5)],
                ),
              ),
            ),
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.peach,
                boxShadow: [
                  BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color(0x55000000)),
                ],
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 48, color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.onPrimary : AppColors.ink;
    final sub = filled
        ? AppColors.onPrimary.withValues(alpha: 0.75)
        : AppColors.ink2;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xxlAll,
        child: Ink(
          decoration: BoxDecoration(
            gradient: filled ? AppGradients.peach : null,
            color: filled ? null : AppColors.glass,
            borderRadius: AppRadius.xxlAll,
            border: filled ? null : Border.all(color: AppColors.line, width: 1.5),
            boxShadow: filled
                ? const [BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x40000000))]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.onPrimary.withValues(alpha: 0.15)
                      : AppColors.pillDeep.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28,
                    color: filled ? AppColors.onPrimary : AppColors.pillDeep),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800, color: fg,
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, color: sub)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

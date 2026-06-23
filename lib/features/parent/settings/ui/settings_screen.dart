// lib/features/parent/settings/ui/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../monetization/ad_banner.dart';
import '../../monetization/ads_provider.dart';
import '../../pairing/ui/connect_child_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onModeChange;
  const SettingsScreen({super.key, this.onModeChange});

  Future<void> _confirmModeChange(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모드 변경'),
        content: const Text(
          '모드 선택 화면으로 돌아갑니다.\n약 정보와 복용 기록은 그대로 유지돼요.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('변경', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok == true) onModeChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.x4l,
        ),
        children: [
          _SettingTile(
            icon: Icons.family_restroom_rounded,
            title: '자녀와 연결',
            subtitle: '자녀가 부모님 복약을 원격으로 확인해요',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectChildScreen())),
          ),
          if (onModeChange != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SettingTile(
              icon: Icons.swap_horiz_rounded,
              title: '모드 변경',
              subtitle: '모드 선택 화면으로 돌아가요',
              onTap: () => _confirmModeChange(context),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          // ── 광고 제거 ──
          if (!ads.removed)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.capsule.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.block_rounded, color: AppColors.capsule),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('광고 제거 — ₩2,900',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            SizedBox(height: 2),
                            Text('한 번 결제하면 영구 제거돼요',
                                style: TextStyle(fontSize: 13, color: AppColors.inkMute)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => ads.purchaseRemoveAds(context),
                    child: const Text('광고 제거 결제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => ads.restorePurchases(),
                    child: const Text('구매 복원', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.jade.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.jade),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('광고가 제거됐어요',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          // ── 앱 정보 ──
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
            child: Text('앱 정보',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.inkMute)),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('KYH 약 알림 v1.0.0',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                SizedBox(height: 2),
                Text('Korean Young Health · 한 알도, 잊지 않게.',
                    style: TextStyle(fontSize: 13, color: AppColors.ink2)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(child: AdBanner()),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Card({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x10000000)),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.xlAll,
      child: InkWell(borderRadius: AppRadius.xlAll, onTap: onTap, child: box),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.pillDeep.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.pillDeep),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.inkMute)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMute),
        ],
      ),
    );
  }
}

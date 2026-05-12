// lib/features/parent/settings/ui/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
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
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          // ── 자녀와 연결 ──
          Card(child: ListTile(
            leading: const Icon(Icons.family_restroom, color: AppColors.pillDeep, size: 32),
            title: const Text('자녀와 연결',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            subtitle: const Text('자녀가 부모님 복약을 원격으로 확인할 수 있어요'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ConnectChildScreen())),
          )),
          if (onModeChange != null) ...[
            const SizedBox(height: 8),
            Card(child: ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppColors.pillDeep, size: 32),
              title: const Text('모드 변경',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              subtitle: const Text('자녀 모드로 전환하거나 모드 선택 화면으로 돌아갈 수 있어요'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirmModeChange(context),
            )),
          ],
          const Divider(height: 32),
          // ── 광고 제거 ──
          if (!ads.removed) ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거 — ₩2,900',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height: 8),
            const Text('한 번 결제하시면 영구 제거됩니다.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            SeniorButton(label: '광고 제거 결제',
                onPressed: () => ads.purchaseRemoveAds(context)),
            const SizedBox(height: 12),
            SeniorButton(label: '구매 복원', color: AppColors.inkMute,
                onPressed: () => ads.restorePurchases()),
          ] else ...[
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('광고 제거됨 ✓',
                  style: TextStyle(fontSize: 22, color: AppColors.jade)),
            )),
          ],
          const Divider(height: 40),
          const Text('앱 정보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('KYH 약 알림 v1.0.0', style: TextStyle(fontSize: 16)),
          const Text('Korean Young Health · 한 알도, 잊지 않게.',
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
          const SizedBox(height: 24),
          const Center(child: AdBanner()),
        ],
      ),
    );
  }
}

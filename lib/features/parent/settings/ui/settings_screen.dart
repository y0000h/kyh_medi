// lib/features/parent/settings/ui/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../monetization/ads_provider.dart';
import '../../pairing/ui/connect_child_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        ],
      ),
    );
  }
}

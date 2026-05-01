// lib/features/parent/monetization/ads_provider.dart   ← STUB (Phase 12)
import 'package:flutter/material.dart';

/// Phase 12 stub. Real implementation coming with IAP integration.
class AdsProvider extends ChangeNotifier {
  bool _removed = false;
  bool get removed => _removed;

  Future<void> init() async {}

  Future<void> purchaseRemoveAds(BuildContext context) async {
    // TODO(Phase 12): Real IAP flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('광고 제거 결제는 출시 후 활성화됩니다 (Phase 12)')),
    );
  }

  Future<void> restorePurchases() async {
    // TODO(Phase 12)
  }
}

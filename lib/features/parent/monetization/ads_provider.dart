import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../settings/data/settings_repository.dart';
import 'iap_service.dart';

/// 광고 제거 결제 상태 + 구매 트리거.
///
/// 결제 영수증이 들어오면 `SettingsRepository.setAdsRemoved(true)`로 캐시
/// → `AdBanner`가 즉시 숨김.
class AdsProvider extends ChangeNotifier {
  final SettingsRepository _settings;
  final IapService _iap = IapService();

  AdsProvider(this._settings);

  bool get removed => _settings.current.adsRemoved;

  Future<void> init() async {
    notifyListeners();
    _iap.listen((p) async {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == IapService.productId) {
          await _settings.setAdsRemoved(true);
          notifyListeners();
        }
      }
      await _iap.complete(p);
    });
  }

  Future<void> purchaseRemoveAds(BuildContext context) async {
    if (!await _iap.isAvailable()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제를 사용할 수 없어요')),
      );
      return;
    }
    final product = await _iap.queryProduct();
    if (product == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러올 수 없어요')),
      );
      return;
    }
    await _iap.buy(product);
  }

  Future<void> restorePurchases() => _iap.restore();

  @override
  void dispose() {
    _iap.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play 인앱 결제(IAP) 래퍼.
///
/// "광고 제거" 평생 상품 1종 (`kyh_remove_ads_lifetime`) 만 다룬다.
class IapService {
  static const String productId = 'kyh_remove_ads_lifetime';
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails?> queryProduct() async {
    final r = await _iap.queryProductDetails({productId});
    if (r.productDetails.isEmpty) return null;
    return r.productDetails.first;
  }

  Future<void> buy(ProductDetails p) async {
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: p),
    );
  }

  Future<void> restore() => _iap.restorePurchases();

  void listen(void Function(PurchaseDetails) onUpdate) {
    _sub = _iap.purchaseStream.listen((list) {
      for (final p in list) {
        onUpdate(p);
      }
    });
  }

  Future<void> complete(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) await _iap.completePurchase(p);
  }

  void dispose() => _sub?.cancel();
}

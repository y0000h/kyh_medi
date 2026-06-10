import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ads_provider.dart';

/// 부모 모드 일부 화면 하단에 노출되는 AdMob 배너.
/// `AdsProvider.removed`가 true면 SizedBox로 사라진다.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  // 테스트 단위 ID. Phase 13 출시 직전 실제 ID로 교체.
  // 구글 공식 배너 테스트 단위는 플랫폼별로 다르다.
  static String get _testUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716' // iOS 배너 테스트
      : 'ca-app-pub-3940256099942544/6300978111'; // Android 배너 테스트

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: _testUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    if (ads.removed || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

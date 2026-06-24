import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kReleaseMode;
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

  // ── AdMob 배너 단위 ID ─────────────────────────────────────────────
  // ⚠️ 출시 전 실제 배너 단위 ID로 교체(AdMob 콘솔 → 앱 → 광고 단위 → 배너).
  //    비워두면 릴리스 빌드에서 배너가 로드되지 않는다 — 테스트 광고를 실수로
  //    출시(AdMob 정책 위반 → 계정 정지 위험)하지 않도록 의도한 안전장치.
  //    앱 단위 ID도 별도로 교체 필요: ios/Runner/Info.plist(GADApplicationIdentifier),
  //    android/.../AndroidManifest.xml(com.google.android.gms.ads.APPLICATION_ID).
  static const _prodUnitIdIOS = '';      // TODO(release): 'ca-app-pub-XXXXXXXX/XXXXXXXX'
  static const _prodUnitIdAndroid = '';  // TODO(release): 'ca-app-pub-XXXXXXXX/XXXXXXXX'

  // 구글 공식 배너 테스트 단위(디버그/프로파일 전용).
  static const _testUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _testUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';

  /// 빌드 모드별 단위 ID. 릴리스인데 실 ID가 비어 있으면 null(배너 미로드).
  static String? get _unitId {
    if (kReleaseMode) {
      final prod = Platform.isIOS ? _prodUnitIdIOS : _prodUnitIdAndroid;
      return prod.isEmpty ? null : prod;
    }
    return Platform.isIOS ? _testUnitIdIOS : _testUnitIdAndroid;
  }

  @override
  void initState() {
    super.initState();
    final unitId = _unitId;
    if (unitId == null) return; // 릴리스 + 실 ID 미설정 → 배너 표시 안 함
    _ad = BannerAd(
      adUnitId: unitId,
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

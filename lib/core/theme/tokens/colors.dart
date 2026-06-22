// lib/core/theme/tokens/colors.dart
import 'package:flutter/material.dart';

/// 부모(어르신) — light premium + refined blue accent.
/// 자녀(보호자) — light + fresh green(연두) accent.
/// 두 팔레트는 같은 role 구조. 값만 다름.
///
/// 토큰 이름(`bg`/`paper`/`ink`/`pillDeep` …)은 의미를 유지한다:
///   bg=배경, paper=카드/표면, paper2=입력 표면, line=경계선,
///   ink=주 텍스트, ink2/inkMute=보조 텍스트, pillDeep/pill=브랜드 액센트.
/// 라이트 전환 시 화면 코드를 건드리지 않도록 "이름은 그대로, 값만 라이트"로.
///
/// `ColorScheme` 슬롯(`primary`/`surface`/`onSurface`)은
/// `Theme.of(context).colorScheme.*`에서 꺼내는 것을 권장.
/// 의미색(`success`/`danger`/`warning`/`border`/`ink2`/`inkMute`)은
/// `AppSemanticColors` ThemeExtension에서.
class AppColors {
  // ── 부모 (light premium + blue) ──
  static const bg = Color(0xFFF3F5F9);             // scaffold (soft cool off-white)
  static const bgElevated = Color(0xFFFAFBFE);     // 배경 그라데이션 상단(거의 흰색)
  static const paper = Color(0xFFFFFFFF);          // surface / card
  static const paper2 = Color(0xFFEDF1F7);         // surfaceAlt / input fill
  static const bg2 = Color(0xFFEDF1F7);            // alias for back-compat
  static const glass = Color(0xFFFFFFFF);          // 카드 베이스(라이트=화이트)
  static const line = Color(0xFFE7EBF2);           // border (hairline)
  static const border = line;                      // alias

  static const ink = Color(0xFF1B2533);            // 주 텍스트 (navy ink)
  static const ink2 = Color(0xFF5A6475);           // 보조 텍스트
  static const inkMute = Color(0xFF97A1B2);        // 흐린 텍스트 / 라벨

  // brand — refined blue accent (위에 올라가는 글자는 white)
  static const pillDeep = Color(0xFF3D7BF5);       // primary
  static const pill = Color(0xFF3D7BF5);           // alias (back-compat)
  static const primaryDeep = Color(0xFF2C62D6);    // 진한 블루
  static const onPrimary = Color(0xFFFFFFFF);      // 액센트 위 텍스트

  // semantic (라이트 배경에서 읽히는 톤)
  static const jade = Color(0xFF22A565);           // success (green)
  static const care = Color(0xFFE85461);           // danger
  static const capsule = Color(0xFFEFA13C);        // warning

  // ── 자녀 (light + fresh green) ──
  static const caregiverBg = Color(0xFFF2F7F0);            // scaffold
  static const caregiverBgElevated = Color(0xFFFAFCF8);
  static const caregiverCard = Color(0xFFFFFFFF);          // surface / card
  static const caregiverSurfaceAlt = Color(0xFFEAF2E6);    // input fill
  static const caregiverGlass = Color(0xFFFFFFFF);
  static const caregiverBorder = Color(0xFFE3EDDE);        // hairline

  static const caregiverInk = Color(0xFF1F2A1E);           // 주 텍스트
  static const caregiverInk2 = Color(0xFF566052);
  static const caregiverInkMute = Color(0xFF93A08D);

  static const caregiverPrimary = Color(0xFF5DAE4E);       // fresh green(연두 계열)
  static const caregiverPrimaryDeep = Color(0xFF479139);
  static const caregiverOnPrimary = Color(0xFFFFFFFF);     // 액센트 위 텍스트
  static const caregiverSuccess = Color(0xFF2FA76A);
  static const caregiverDanger = Color(0xFFE85461);
  static const caregiverWarning = Color(0xFFEFA13C);
}

/// 라이트 배경의 은은한 세로 그라데이션과 액센트 그라데이션.
class AppGradients {
  /// 부모 배경 — 위가 거의 흰색, 아래로 살짝 쿨 그레이.
  static const seniorBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgElevated, AppColors.bg],
  );

  /// 자녀 배경.
  static const caregiverBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.caregiverBgElevated, AppColors.caregiverBg],
  );

  /// 블루 액센트 그라데이션(히어로/진행률/버튼 강조). 이름은 back-compat 위해 `peach` 유지.
  static const peach = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B97FF), Color(0xFF3D7BF5)],
  );

  /// 연두 액센트 그라데이션.
  static const lime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7BC95B), Color(0xFF5DAE4E)],
  );
}

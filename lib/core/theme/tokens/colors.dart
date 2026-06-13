// lib/core/theme/tokens/colors.dart
import 'package:flutter/material.dart';

/// 부모(어르신) — warm espresso dark + peach accent (LILOO 레퍼런스 무드).
/// 자녀(보호자) — cool charcoal dark + soft green(연두) accent.
/// 두 팔레트는 같은 role 구조. 값만 다름.
///
/// 토큰 이름(`bg`/`paper`/`ink`/`pillDeep` …)은 의미를 유지한다:
///   bg=배경, paper=카드/표면, paper2=입력 표면, line=경계선,
///   ink=주 텍스트, ink2/inkMute=보조 텍스트, pillDeep/pill=브랜드 액센트.
/// 다크 전환 시 화면 코드를 건드리지 않도록 "이름은 그대로, 값만 다크"로 갈아끼웠다.
///
/// `ColorScheme` 슬롯에 들어가는 `primary` / `surface` / `bg` / `ink`는
/// 그대로 `Theme.of(context).colorScheme.*`에서 꺼내는 것을 권장.
/// 의미색(`success`/`danger`/`warning`/`border`/`ink2`/`inkMute`)은
/// `AppSemanticColors` ThemeExtension에서.
class AppColors {
  // ── 부모 (warm espresso dark) ──
  static const bg = Color(0xFF2A201A);             // scaffold (deep espresso)
  static const bgElevated = Color(0xFF332720);     // 살짝 들린 배경(헤더 그라데이션 상단)
  static const paper = Color(0xFF3C2F27);          // surface / card
  static const paper2 = Color(0xFF473930);         // surfaceAlt / input fill
  static const bg2 = Color(0xFF473930);            // alias for back-compat
  static const glass = Color(0xFF4A3B32);          // 반투명 글래스 카드 베이스
  static const line = Color(0x1FF3E9E0);           // border — 12% cream hairline
  static const border = line;                      // alias

  static const ink = Color(0xFFF4EAE1);            // 주 텍스트 (cream)
  static const ink2 = Color(0xFFCBB9AC);           // 보조 텍스트
  static const inkMute = Color(0xFF9C8B7E);        // 흐린 텍스트 / 라벨

  // brand — peach/salmon accent (밝은 액센트 → 위에 올라가는 글자는 dark)
  static const pillDeep = Color(0xFFF2C49C);       // primary
  static const pill = Color(0xFFF2C49C);           // alias (back-compat)
  static const primaryDeep = Color(0xFFE7A877);    // 진한 피치
  static const onPrimary = Color(0xFF3A2417);      // 액센트 위 텍스트(짙은 갈색)

  // semantic (다크 배경에서 읽히는 톤)
  static const jade = Color(0xFF7FBE9E);           // success
  static const care = Color(0xFFE57A66);           // danger
  static const capsule = Color(0xFFE4B466);        // warning

  // ── 자녀 (cool charcoal dark + soft green) ──
  static const caregiverBg = Color(0xFF1E241D);            // scaffold
  static const caregiverBgElevated = Color(0xFF252D23);
  static const caregiverCard = Color(0xFF2C342A);          // surface / card
  static const caregiverSurfaceAlt = Color(0xFF36402F);    // input fill
  static const caregiverGlass = Color(0xFF38442F);
  static const caregiverBorder = Color(0x1FE9F3E2);        // 12% green-tinted hairline

  static const caregiverInk = Color(0xFFEDF4E7);           // 주 텍스트
  static const caregiverInk2 = Color(0xFFC2CDB8);
  static const caregiverInkMute = Color(0xFF8C9882);

  static const caregiverPrimary = Color(0xFFBFE08F);       // 연두 accent
  static const caregiverPrimaryDeep = Color(0xFF9ECB6E);
  static const caregiverOnPrimary = Color(0xFF22301A);     // 액센트 위 텍스트
  static const caregiverSuccess = Color(0xFF8AD0A0);
  static const caregiverDanger = Color(0xFFE5897A);
  static const caregiverWarning = Color(0xFFE3C56A);
}

/// 레퍼런스의 따뜻한 세로 그라데이션(배경/헤더)과 액센트 그라데이션.
class AppGradients {
  /// 부모 배경 — 위가 살짝 밝은 에스프레소.
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

  /// 피치 액센트 그라데이션(히어로 버튼/배지 강조용).
  static const peach = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6CFA6), Color(0xFFEAA877)],
  );

  /// 연두 액센트 그라데이션.
  static const lime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCBE89B), Color(0xFF9ECB6E)],
  );
}

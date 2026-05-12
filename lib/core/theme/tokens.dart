// lib/core/theme/tokens.dart
import 'package:flutter/material.dart';

/// 부모 모드 (어르신) — refined warm earthy.
/// 자녀 모드 (보호자) — cool clinical.
/// 두 팔레트는 같은 role 구조. 값만 다름.
class AppColors {
  // ── 부모 (warm earthy modern) ──
  static const bg = Color(0xFFF5F1EC);
  static const paper = Color(0xFFFFFFFF);          // surface
  static const paper2 = Color(0xFFFAF7F2);         // surfaceAlt
  static const bg2 = Color(0xFFFAF7F2);            // alias for back-compat
  static const line = Color(0xFFE0D9CC);           // border

  static const ink = Color(0xFF1A1A1A);
  static const ink2 = Color(0xFF5A544A);
  static const inkMute = Color(0xFF8A8378);

  // brand
  static const pillDeep = Color(0xFFC26644);       // primary
  static const pill = Color(0xFFC26644);           // alias (back-compat)
  static const primaryDeep = Color(0xFF8A4A2D);

  // semantic
  static const jade = Color(0xFF5A8175);           // success
  static const care = Color(0xFFB33A3A);           // danger
  static const capsule = Color(0xFFC99A4A);        // warning

  // ── 자녀 (cool clinical) ──
  static const caregiverBg = Color(0xFFF4F6F8);
  static const caregiverCard = Color(0xFFFFFFFF);
  static const caregiverSurfaceAlt = Color(0xFFF9FAFB);
  static const caregiverBorder = Color(0xFFE2E6EB);

  static const caregiverInk = Color(0xFF0F172A);
  static const caregiverInk2 = Color(0xFF334155);
  static const caregiverInkMute = Color(0xFF64748B);

  static const caregiverPrimary = Color(0xFF3B82C4);
  static const caregiverPrimaryDeep = Color(0xFF1E5A8C);
  static const caregiverSuccess = Color(0xFF10B981);
  static const caregiverDanger = Color(0xFFEF4444);
  static const caregiverWarning = Color(0xFFF59E0B);
}

/// 4pt grid. 화면 padding 기본 xl(20), 카드 내부 padding 기본 xl(20),
/// 카드 사이 간격 기본 md~lg(12~16).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
}

class AppRadius {
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0A000000)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0F000000)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x14000000)),
  ];
}

class AppSizes {
  // 부모 (시니어, 어르신 가독성 우선)
  static const double bodyFontSize = 18.0;
  static const double bodyDenseFontSize = 16.0;
  static const double buttonFontSize = 18.0;     // labelLarge
  static const double titleFontSize = 24.0;
  static const double displayFontSize = 32.0;
  static const double minButtonHeight = 56.0;
  static const double largeButtonHeight = 80.0;
  static const double padding = AppSpacing.xl;   // 화면 기본 padding 20

  // 자녀 (보호자, 표준)
  static const double caregiverBodyFontSize = 15.0;
  static const double caregiverButtonFontSize = 15.0;
  static const double caregiverTitleFontSize = 24.0;
  static const double caregiverMinButtonHeight = 48.0;
}

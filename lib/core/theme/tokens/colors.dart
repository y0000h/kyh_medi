// lib/core/theme/tokens/colors.dart
import 'package:flutter/material.dart';

/// 부모(어르신) — refined warm earthy.
/// 자녀(보호자) — cool clinical.
/// 두 팔레트는 같은 role 구조. 값만 다름.
///
/// `ColorScheme` 슬롯에 들어가는 `primary` / `surface` / `bg` / `ink`는
/// 그대로 `Theme.of(context).colorScheme.*`에서 꺼내는 것을 권장.
/// `success` / `danger` / `warning` / `border` / `ink2` / `inkMute`처럼
/// Material 스키마에 자리가 없는 의미색은 `AppSemanticColors` ThemeExtension에서.
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

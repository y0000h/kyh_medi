// lib/core/theme/tokens.dart
import 'package:flutter/material.dart';

class AppColors {
  // 부모 모드 (시니어)
  static const bg = Color(0xFFECE8E1);
  static const bg2 = Color(0xFFDDD8CD);
  static const paper = Color(0xFFFBFAF6);
  static const paper2 = Color(0xFFF4F1EA);
  static const ink = Color(0xFF1A1A1A);
  static const ink2 = Color(0xFF3D3D3D);
  static const inkMute = Color(0xFF8A8578);
  static const line = Color(0xFFC9C3B5);
  static const pill = Color(0xFFD88E5E);
  static const pillDeep = Color(0xFFB86F40);
  static const care = Color(0xFFC8554D);
  static const capsule = Color(0xFFC99A4A);
  static const jade = Color(0xFF6B8E7F);

  // 자녀 모드 (Material 일반)
  static const caregiverPrimary = Color(0xFF2563EB);
  static const caregiverBg = Color(0xFFFAFAFA);
  static const caregiverCard = Colors.white;
}

class AppSizes {
  // 부모 (시니어)
  static const double bodyFontSize = 18.0;
  static const double buttonFontSize = 22.0;
  static const double titleFontSize = 28.0;
  static const double minButtonHeight = 56.0;
  static const double largeButtonHeight = 80.0;
  static const double padding = 20.0;

  // 자녀 (Material 기본)
  static const double caregiverBodyFontSize = 14.0;
  static const double caregiverButtonFontSize = 16.0;
  static const double caregiverMinButtonHeight = 48.0;
}

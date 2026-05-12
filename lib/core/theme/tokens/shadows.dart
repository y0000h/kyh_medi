// lib/core/theme/tokens/shadows.dart
import 'package:flutter/widgets.dart';

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

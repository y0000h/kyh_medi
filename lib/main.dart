import 'package:flutter/material.dart';

/// 임시 placeholder. Phase 6에서 모드 분기 진입점 (HiveInit + SupabaseInit + FirebaseInit + ModeSelect)으로 교체됨.
void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          'KYH 약 알림\n셋업 중',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  ));
}

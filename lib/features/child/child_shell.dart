import 'package:flutter/material.dart';

/// 자녀(보호자) 모드의 메인 셸. Phase 9에서 본격 구현될 예정인 stub.
class ChildShell extends StatelessWidget {
  const ChildShell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자녀 모드')),
      body: const Center(child: Text('자녀 모드 — Phase 9에서 구현됩니다')),
    );
  }
}

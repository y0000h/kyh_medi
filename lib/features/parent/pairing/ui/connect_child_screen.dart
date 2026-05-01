// lib/features/parent/pairing/ui/connect_child_screen.dart   ← STUB (Phase 8)
import 'package:flutter/material.dart';

/// Phase 8 stub. Real implementation: 6-digit pairing code + 자녀 list.
class ConnectChildScreen extends StatelessWidget {
  const ConnectChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자녀와 연결')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '자녀와 연결 기능은 Phase 8에서 구현됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/supabase/supabase_init.dart';
import 'auth/ui/child_login_screen.dart';
import 'home/ui/child_home_provider.dart';
import 'home/ui/child_home_screen.dart';

/// 자녀(보호자) 모드의 메인 셸 — 인증 상태 기반 라우팅.
class ChildShell extends StatefulWidget {
  const ChildShell({super.key});

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  bool _signedIn = SupabaseInit.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    SupabaseInit.client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() => _signedIn = event.session?.user != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const ChildLoginScreen();
    }
    return ChangeNotifierProvider(
      create: (_) => ChildHomeProvider(),
      child: const ChildHomeScreen(),
    );
  }
}

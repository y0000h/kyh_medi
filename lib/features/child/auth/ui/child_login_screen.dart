import 'package:flutter/material.dart';
import '../child_auth_service.dart';

/// 자녀 로그인 화면 — Google OAuth + 이메일 2탭.
class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _auth = ChildAuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _go(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      await _auth.ensureChildUserRow(displayName: _name.text.trim());
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자녀 로그인'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Google'), Tab(text: '이메일')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_googleTab(), _emailTab()],
      ),
    );
  }

  Widget _googleTab() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom,
                size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Google 계정으로 빠르게 시작',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Google로 로그인'),
              onPressed: _loading ? null : () => _go(_auth.signInWithGoogle),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );

  Widget _emailTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름 (가입 시)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () => _go(() => _auth.signUpWithEmail(
                        email: _email.text.trim(),
                        password: _password.text,
                        displayName: _name.text.trim(),
                      )),
              child: const Text('가입하기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _go(() => _auth.signInWithEmail(
                        email: _email.text.trim(),
                        password: _password.text,
                      )),
              child: const Text('이미 계정이 있어요 — 로그인'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );
}

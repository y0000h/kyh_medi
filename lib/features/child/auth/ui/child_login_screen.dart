import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../child_auth_service.dart';

/// 자녀 로그인 화면 — Google OAuth + 이메일 OTP 2탭.
///
/// - 이메일 탭은 비밀번호 없는 OTP 방식: 이메일 입력 → 인증번호 메일 발송 →
///   6자리 코드 입력 → 검증. 첫 로그인 시 자동 계정 생성.
class ChildLoginScreen extends StatefulWidget {
  final VoidCallback? onModeChange;
  const ChildLoginScreen({super.key, this.onModeChange});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _auth = ChildAuthService();
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _email.dispose();
    _name.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '올바른 이메일을 입력해주세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await _auth.sendEmailOtp(
        email: email,
        displayName: _name.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _info = '$email 으로 6자리 인증번호를 보냈어요. 메일 확인 후 입력해주세요.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = '인증번호 발송 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otp.text.trim();
    if (code.length < 6) {
      setState(() => _error = '인증번호를 끝까지 입력해주세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.verifyEmailOtp(email: _email.text.trim(), token: code);
      await _auth.ensureChildUserRow(displayName: _name.text.trim());
      // child_shell이 onAuthStateChange로 전환됨 — 추가 navigation 불필요
    } catch (e) {
      if (mounted) setState(() => _error = '인증번호가 맞지 않거나 만료됐어요');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.signInWithGoogle();
      await _auth.ensureChildUserRow(displayName: _name.text.trim());
    } catch (e) {
      if (mounted) setState(() => _error = 'Google 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetEmailFlow() {
    setState(() {
      _otpSent = false;
      _otp.clear();
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onModeChange == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '모드 변경',
                onPressed: _loading ? null : widget.onModeChange,
              ),
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
            const Icon(Icons.family_restroom, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text('Google 계정으로 빠르게 시작',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Google로 로그인'),
              onPressed: _loading ? null : _googleSignIn,
            ),
            if (_error != null && _tab.index == 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );

  Widget _emailTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_otpSent) ..._emailStep() else ..._otpStep(),
            if (_info != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_info!, style: const TextStyle(color: Colors.green)),
              ),
            if (_error != null && _tab.index == 1)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );

  List<Widget> _emailStep() => [
        const Text('이메일로 인증번호를 받아 로그인합니다.\n비밀번호는 필요 없어요.',
            style: TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: '이름 (첫 가입 시)',
            helperText: '이미 가입돼 있으면 비워둬도 돼요',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'your@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          child: Text(_loading ? '발송 중…' : '인증번호 받기'),
        ),
      ];

  List<Widget> _otpStep() => [
        Text('${_email.text.trim()} 로 보낸 인증번호를 입력해주세요',
            style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _otp,
          decoration: const InputDecoration(
            labelText: '인증번호',
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _verifyOtp,
          child: Text(_loading ? '확인 중…' : '확인'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _sendOtp,
          child: const Text('인증번호 재발송'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _loading ? null : _resetEmailFlow,
          child: const Text('이메일 다시 입력'),
        ),
      ];
}

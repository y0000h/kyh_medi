import 'package:flutter/material.dart';
import '../../../../core/supabase/supabase_init.dart';

/// 자녀가 부모 페어링 코드(6자리)를 입력 → `redeem_pairing_code` RPC 호출.
class AddParentScreen extends StatefulWidget {
  const AddParentScreen({super.key});

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _code = TextEditingController();
  final _label = TextEditingController(text: '엄마');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = '6자리 코드를 정확히 입력해주세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseInit.client.rpc('redeem_pairing_code', params: {
        'p_code': _code.text.trim(),
        'p_label': _label.text.trim().isEmpty ? '부모님' : _label.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부모님 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '부모님 폰의 "자녀와 연결" 화면에서 받은 6자리 코드를 입력해주세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 32,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: '6자리 코드',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: '부모님 별칭',
                hintText: '예: 엄마, 아빠',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _redeem,
              child: Text(_loading ? '연결 중...' : '연결하기'),
            ),
          ],
        ),
      ),
    );
  }
}

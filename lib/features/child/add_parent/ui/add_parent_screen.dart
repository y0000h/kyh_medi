import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
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
      backgroundColor: AppColors.caregiverBg,
      appBar: AppBar(
        title: const Text('부모님 추가', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 64,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 안내 카드
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.caregiverPrimary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.caregiverPrimaryDeep),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        '부모님 폰의 "자녀와 연결" 화면에서 받은\n6자리 코드를 입력해주세요.',
                        style: TextStyle(fontSize: 14, color: AppColors.caregiverInk2, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text('6자리 코드',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.caregiverInk2)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.caregiverCard,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.caregiverBorder, width: 1),
                ),
                child: TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 34, letterSpacing: 12, fontWeight: FontWeight.w800,
                    color: AppColors.caregiverInk,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(letterSpacing: 12, color: AppColors.caregiverInkMute),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('부모님 별칭',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.caregiverInk2)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _label,
                decoration: const InputDecoration(hintText: '예: 엄마, 아빠'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(_error!, style: const TextStyle(color: AppColors.caregiverDanger, fontSize: 14)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _redeem,
                  child: Text(_loading ? '연결 중…' : '연결하기',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

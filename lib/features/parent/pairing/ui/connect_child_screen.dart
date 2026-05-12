import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import 'pairing_provider.dart';

/// 부모 측 "자녀와 연결" 화면. 6자리 코드 발급 + 10분 카운트다운 + 페어링 목록.
class ConnectChildScreen extends StatefulWidget {
  const ConnectChildScreen({super.key});
  @override
  State<ConnectChildScreen> createState() => _ConnectChildScreenState();
}

class _ConnectChildScreenState extends State<ConnectChildScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PairingProvider>().loadPairings());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final exp = context.read<PairingProvider>().codeExpiresAt;
      if (exp == null) return;
      final r = exp.difference(DateTime.now());
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtRemaining() {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PairingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('자녀와 연결')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.line, width: 2),
            ),
            child: Column(children: [
              if (pp.code == null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '자녀에게 보여드릴 6자리 코드를 받으세요.\n10분 안에 자녀가 입력해야 해요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else ...[
                Text(
                  pp.code!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 60,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '남은 시간 ${_fmtRemaining()}',
                  style: const TextStyle(fontSize: 16, color: AppColors.ink2),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          if (pp.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(pp.error!, style: const TextStyle(color: AppColors.care)),
            ),
          SeniorButton(
            label: pp.loading ? '발급 중...' : '코드 받기',
            onPressed: pp.loading
                ? null
                : () async {
                    await context.read<PairingProvider>().issueCode();
                    _startTicker();
                  },
          ),
          const Divider(height: 48),
          const Text(
            '연결된 자녀',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (pp.pairings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '아직 연결된 자녀가 없어요',
                style: TextStyle(color: AppColors.ink2),
              ),
            )
          else
            ...pp.pairings.map((p) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 32, color: AppColors.pillDeep),
                    title: Text(
                      p.childDisplayName ?? '자녀',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('연결: ${p.pairedAt.toLocal()}'),
                    trailing: TextButton(
                      onPressed: () =>
                          context.read<PairingProvider>().unpair(p.pairingId),
                      child: const Text('연결 해제'),
                    ),
                  ),
                )),
        ]),
      ),
    );
  }
}

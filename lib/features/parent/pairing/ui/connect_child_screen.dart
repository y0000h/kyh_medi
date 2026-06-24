import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import 'pairing_provider.dart';

/// 부모 측 "자녀와 연결" 화면. 6자리 코드 발급 + 10분 카운트다운 + 페어링 목록.
/// 자녀 측 [AddParentScreen](../../../child/add_parent/ui/add_parent_screen.dart)의 블루 카운터파트.
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
    Future.microtask(() {
      if (!mounted) return;
      context.read<PairingProvider>().loadPairings();
    });
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('자녀와 연결', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 64,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.x4l,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // 안내 카드
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.pillDeep.withValues(alpha: 0.10),
                borderRadius: AppRadius.lgAll,
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryDeep),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '자녀 폰의 "부모님 추가" 화면에서 입력할\n6자리 코드를 발급하세요. 10분 안에 입력해야 해요.',
                      style: TextStyle(fontSize: 14, color: AppColors.ink2, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // 코드 표시 카드
            _codeCard(pp),
            if (pp.error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(pp.error!, style: const TextStyle(color: AppColors.care, fontSize: 14)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: pp.loading
                    ? null
                    : () async {
                        await context.read<PairingProvider>().issueCode();
                        _startTicker();
                      },
                child: Text(pp.loading ? '발급 중…' : (pp.code == null ? '코드 받기' : '코드 다시 받기'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: AppSpacing.x3l),
            const Text('연결된 자녀',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: AppSpacing.md),
            if (pp.pairings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: AppRadius.lgAll,
                ),
                child: const Text('아직 연결된 자녀가 없어요',
                    style: TextStyle(fontSize: 15, color: AppColors.inkMute)),
              )
            else
              ...pp.pairings.map(_pairingCard),
          ]),
        ),
      ),
    );
  }

  Widget _codeCard(PairingProvider pp) {
    final hasCode = pp.code != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3l, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x10000000)),
        ],
      ),
      child: Column(children: [
        if (!hasCode)
          const Text(
            '자녀에게 보여드릴 6자리 코드를\n아래 버튼으로 받으세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.ink2, height: 1.5),
          )
        else ...[
          Text(
            pp.code!,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
              color: AppColors.pillDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pillDeep.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillAll,
            ),
            child: Text('남은 시간 ${_fmtRemaining()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
          ),
        ],
      ]),
    );
  }

  Widget _pairingCard(p) {
    final pairedFmt = DateFormat('yyyy.MM.dd', 'ko_KR').format(p.pairedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.pillDeep.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 26, color: AppColors.pillDeep),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.childDisplayName ?? '자녀',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('연결일 $pairedFmt',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkMute)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.read<PairingProvider>().unpair(p.pairingId),
              child: const Text('연결 해제',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.care)),
            ),
          ],
        ),
      ),
    );
  }
}

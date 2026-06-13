// lib/features/parent/intake/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../slot/ui/slot_form_screen.dart';
import '../../slot/ui/slots_provider.dart';
import '../domain/dose_event.dart';
import 'intake_provider.dart';
import 'intake_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<IntakeProvider>().loadToday();
    });
    NotificationService.onTap = (payload) {
      // payload: "slot:<slotId>"
      if (!payload.startsWith('slot:')) return;
      final slotId = payload.substring(5);
      final view = context.read<IntakeProvider>().today
          .where((t) => t.slot.id == slotId).firstOrNull;
      if (view != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => IntakeCheckScreen(slotView: view),
        ));
      }
    };
  }

  StatusKind _statusKind(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return StatusKind.success;
      case DoseEvent.statusMissed: return StatusKind.danger;
      default: return StatusKind.warning;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return '복용 완료';
      case DoseEvent.statusMissed: return '미복용';
      default: return '복용 전';
    }
  }

  String _daysLabel(int mask) {
    if (mask == 127) return '매일';
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) => (mask & (1 << i)) != 0 ? labels[i] : null)
        .where((x) => x != null).join(' ');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '편안한 새벽이에요';
    if (h < 12) return '좋은 아침이에요';
    if (h < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }

  Future<void> _editSlot(TodaySlotView t) async {
    final medIds = t.medications.map((m) => m.id).toList();
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SlotFormScreen(
        existing: t.slot,
        existingMedicationIds: medIds,
      )),
    );
    if (updated == true && mounted) {
      await context.read<IntakeProvider>().loadToday();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간 슬롯이 수정됐어요')),
      );
    }
  }

  Future<void> _deleteSlot(TodaySlotView t) async {
    final hh = t.slot.hour.toString().padLeft(2, '0');
    final mm = t.slot.minute.toString().padLeft(2, '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시간 슬롯 삭제'),
        content: Text(
          '${t.slot.label} $hh:$mm 슬롯을 삭제할까요?\n예약된 알림도 함께 취소돼요.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.care),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<SlotsProvider>().remove(t.slot.id);
    if (!mounted) return;
    await context.read<IntakeProvider>().loadToday();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${t.slot.label} 슬롯이 삭제됐어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = context.watch<IntakeProvider>().today;
    final taken = today.where((t) => t.status == DoseEvent.statusTaken).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
          ),
          children: [
            _Hero(greeting: _greeting(), total: today.length, taken: taken),
            const SizedBox(height: AppSpacing.xxl),
            if (today.isEmpty)
              const _EmptyToday()
            else
              ...today.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _SlotCard(
                      view: t,
                      hh: t.slot.hour.toString().padLeft(2, '0'),
                      mm: t.slot.minute.toString().padLeft(2, '0'),
                      daysLabel: _daysLabel(t.slot.daysOfWeek),
                      statusLabel: _statusLabel(t.status),
                      statusKind: _statusKind(t.status),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => IntakeCheckScreen(slotView: t),
                        ));
                        if (context.mounted) {
                          context.read<IntakeProvider>().loadToday();
                        }
                      },
                      onEdit: () => _editSlot(t),
                      onDelete: () => _deleteSlot(t),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

/// 인사 + "오늘의 약" + 진행 요약을 담은 히어로 헤더.
class _Hero extends StatelessWidget {
  final String greeting;
  final int total;
  final int taken;
  const _Hero({required this.greeting, required this.total, required this.taken});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(greeting,
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink2,
            )),
        const SizedBox(height: 2),
        Text('오늘의 약',
            style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: AppSpacing.lg),
        // 진행 요약 글래스 칩
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: AppGradients.peach,
            borderRadius: AppRadius.xlAll,
            boxShadow: const [
              BoxShadow(offset: Offset(0, 6), blurRadius: 20, color: Color(0x33000000)),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.medication_rounded, color: cs.onPrimary, size: 30),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  total == 0
                      ? '등록된 약이 없어요'
                      : (taken >= total
                          ? '오늘 약을 모두 드셨어요 🎉'
                          : '오늘 $total개 중 $taken개 드셨어요'),
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x4l),
      child: Column(
        children: [
          Icon(Icons.bedtime_outlined, size: 64, color: AppColors.inkMute),
          const SizedBox(height: AppSpacing.lg),
          const Text('오늘 드실 약이 없어요.\n약과 시간을 등록해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: AppColors.ink2, height: 1.4)),
        ],
      ),
    );
  }
}

/// 글래스 톤의 시간 슬롯 카드.
class _SlotCard extends StatelessWidget {
  final TodaySlotView view;
  final String hh, mm, daysLabel, statusLabel;
  final StatusKind statusKind;
  final VoidCallback onTap, onEdit, onDelete;

  const _SlotCard({
    required this.view,
    required this.hh,
    required this.mm,
    required this.daysLabel,
    required this.statusLabel,
    required this.statusKind,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x26000000)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlAll,
        child: InkWell(
          borderRadius: AppRadius.xlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$hh:$mm',
                      style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800,
                        color: AppColors.ink, letterSpacing: -0.5,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  Text(view.slot.label,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        letterSpacing: 0.6, color: AppColors.inkMute,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  Text(daysLabel,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
                ]),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final m in view.medications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(m.name,
                            style: const TextStyle(
                              fontSize: AppSizes.bodyFontSize, color: AppColors.ink,
                            )),
                      ),
                  ])),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(label: statusLabel, kind: statusKind),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.inkMute),
                      tooltip: '슬롯 옵션',
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 16))),
                        PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(fontSize: 16, color: AppColors.care))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

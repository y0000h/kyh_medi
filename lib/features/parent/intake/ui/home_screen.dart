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
    Future.microtask(() => context.read<IntakeProvider>().loadToday());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 약', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: today.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('오늘 드실 약이 없어요.\n약과 시간을 등록해주세요.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: today.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final t = today[i];
                final hh = t.slot.hour.toString().padLeft(2, '0');
                final mm = t.slot.minute.toString().padLeft(2, '0');
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: AppShadows.md,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: AppRadius.lgAll,
                    child: InkWell(
                      borderRadius: AppRadius.lgAll,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => IntakeCheckScreen(slotView: t),
                        ));
                        if (context.mounted) context.read<IntakeProvider>().loadToday();
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('$hh:$mm', style: Theme.of(context).textTheme.displayLarge),
                              const SizedBox(height: AppSpacing.xs),
                              Text(t.slot.label,
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6, color: AppColors.inkMute,
                                  )),
                              const SizedBox(height: AppSpacing.xs),
                              Text(_daysLabel(t.slot.daysOfWeek),
                                  style: const TextStyle(
                                    fontSize: 13, color: AppColors.ink2,
                                  )),
                            ]),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final m in t.medications)
                                  Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                    child: Text(m.name,
                                        style: const TextStyle(fontSize: AppSizes.bodyFontSize, color: AppColors.ink))),
                              ])),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(label: _statusLabel(t.status), kind: _statusKind(t.status)),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: AppColors.inkMute),
                                  tooltip: '슬롯 옵션',
                                  onSelected: (v) {
                                    if (v == 'edit') _editSlot(t);
                                    if (v == 'delete') _deleteSlot(t);
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
              },
            ),
    );
  }
}

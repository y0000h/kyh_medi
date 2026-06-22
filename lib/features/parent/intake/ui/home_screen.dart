// lib/features/parent/intake/ui/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../../shared/widgets/ring_progress.dart';
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

  Future<void> _markTaken(TodaySlotView t) async {
    await context.read<IntakeProvider>().markSlotTaken(t.slot.id, t.scheduledAt);
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
    final total = today.length;
    final taken = today.where((t) => t.status == DoseEvent.statusTaken).length;
    final remaining = total - taken;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.x4l,
          ),
          children: [
            const _WeekStrip(),
            const SizedBox(height: AppSpacing.xl),
            _ProgressCard(total: total, taken: taken, remaining: remaining),
            const SizedBox(height: AppSpacing.xxl),
            if (today.isEmpty)
              const _EmptyToday()
            else
              ..._buildTimeline(today),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(List<TodaySlotView> today) {
    final widgets = <Widget>[];
    for (var i = 0; i < today.length; i++) {
      final t = today[i];
      final hh = t.slot.hour.toString().padLeft(2, '0');
      final mm = t.slot.minute.toString().padLeft(2, '0');
      widgets.add(Padding(
        padding: EdgeInsets.only(
          top: i == 0 ? 0 : AppSpacing.xl, bottom: AppSpacing.md,
        ),
        child: Text('$hh:$mm',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink,
            )),
      ));
      widgets.add(_DoseCard(
        view: t,
        onTaken: () => _markTaken(t),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => IntakeCheckScreen(slotView: t),
          ));
          if (mounted) context.read<IntakeProvider>().loadToday();
        },
        onEdit: () => _editSlot(t),
        onDelete: () => _deleteSlot(t),
      ));
    }
    return widgets;
  }
}

// ── 주간 캘린더 스트립 ──────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    // 이번 주 일요일 시작
    final sunday = today0.subtract(Duration(days: today0.weekday % 7));
    const dows = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.chevron_left, color: AppColors.inkMute),
            Expanded(
              child: Text('${now.year}년 ${now.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink,
                  )),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMute),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: List.generate(7, (i) {
            final day = sunday.add(Duration(days: i));
            final isToday = day == today0;
            final isSun = i == 0;
            final isSat = i == 6;
            return Expanded(
              child: Column(
                children: [
                  Text(dows[i],
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isToday
                            ? AppColors.pillDeep
                            : (isSun
                                ? AppColors.care.withValues(alpha: 0.9)
                                : (isSat
                                    ? AppColors.ink2
                                    : AppColors.inkMute)),
                      )),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 40, height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isToday ? AppGradients.peach : null,
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: Text('${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday ? AppColors.onPrimary : AppColors.ink,
                        )),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── 진행률 카드 ────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int total, taken, remaining;
  const _ProgressCard({required this.total, required this.taken, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : taken / total;
    final String title;
    final String subtitle;
    if (total == 0) {
      title = '약을 등록해요';
      subtitle = '하단 + 로 약을 추가하세요';
    } else if (remaining == 0) {
      title = '오늘 다 드셨어요!';
      subtitle = '완벽해요 🎉';
    } else if (value >= 0.5) {
      title = '거의 다 왔어요!';
      subtitle = '오늘 남은 약 $remaining회';
    } else {
      title = '오늘도 챙겨요!';
      subtitle = '오늘 남은 약 $remaining회';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 18, color: Color(0x26000000)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink,
                    )),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.jade),
                    const SizedBox(width: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 15, color: AppColors.ink2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          RingProgress(
            value: value,
            color: AppColors.pillDeep,
            trackColor: AppColors.pillDeep.withValues(alpha: 0.18),
            textColor: AppColors.pillDeep,
          ),
        ],
      ),
    );
  }
}

// ── 약 복용 카드 ───────────────────────────────────────────────────
class _DoseCard extends StatelessWidget {
  final TodaySlotView view;
  final VoidCallback onTaken, onTap, onEdit, onDelete;

  const _DoseCard({
    required this.view,
    required this.onTaken,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = view.status == DoseEvent.statusTaken;
    final isMissed = view.status == DoseEvent.statusMissed;
    final names = view.medications.map((m) => m.name).join(', ');
    final photo = view.medications
        .map((m) => m.photoPath)
        .where((p) => p != null && File(p).existsSync())
        .firstOrNull;

    return Opacity(
      opacity: isTaken ? 0.6 : 1,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isTaken ? AppColors.paper2 : AppColors.glass,
              borderRadius: AppRadius.xlAll,
              border: Border.all(
                color: isMissed ? AppColors.care.withValues(alpha: 0.5) : AppColors.line,
                width: 1,
              ),
              boxShadow: isTaken
                  ? null
                  : const [BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x22000000))],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppRadius.xlAll,
              child: InkWell(
                borderRadius: AppRadius.xlAll,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _PillAvatar(photoPath: photo),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(names,
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    )),
                                const SizedBox(height: 2),
                                Text('${view.medications.length}개',
                                    style: const TextStyle(fontSize: 14, color: AppColors.inkMute)),
                              ],
                            ),
                          ),
                          _Badge(text: view.slot.label),
                          _MoreButton(onEdit: onEdit, onDelete: onDelete),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (isTaken)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: 0.5),
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            '${view.scheduledAt.hour < 12 ? "오전" : "오후"} '
                            '${view.scheduledAt.hour.toString().padLeft(2, "0")}:'
                            '${view.scheduledAt.minute.toString().padLeft(2, "0")}',
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkMute,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onTaken,
                            child: Text(isMissed ? '지금 먹었어요' : '먹었어요',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isTaken)
            Positioned(
              right: 24, bottom: 18,
              child: Transform.rotate(
                angle: -0.25,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.jade, width: 2.5),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Text('완료',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.jade,
                        letterSpacing: 2,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillAvatar extends StatelessWidget {
  final String? photoPath;
  const _PillAvatar({this.photoPath});
  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: Image.file(File(photoPath!), width: 56, height: 56, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: AppColors.pillDeep.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.medication_rounded, color: AppColors.pillDeep, size: 28),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pillDeep.withValues(alpha: 0.16),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.pillDeep,
          )),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onEdit, onDelete;
  const _MoreButton({required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.inkMute, size: 20),
      tooltip: '옵션',
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 16))),
        PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(fontSize: 16, color: AppColors.care))),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4l, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.medication_outlined, size: 48, color: AppColors.inkMute),
          const SizedBox(height: AppSpacing.md),
          const Text('복용 일정이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

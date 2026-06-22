import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../medication/domain/medication.dart';
import '../../medication/ui/medications_provider.dart';
import '../domain/time_slot.dart';
import 'slots_provider.dart';
import 'slot_form_screen.dart';

class SlotListScreen extends StatelessWidget {
  const SlotListScreen({super.key});

  String _daysLabel(int mask) {
    if (mask == 127) return '매일';
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) => (mask & (1 << i)) != 0 ? labels[i] : null)
        .where((x) => x != null).join(' ');
  }

  Future<void> _confirmDelete(BuildContext context, TimeSlot s) async {
    final hh = s.hour.toString().padLeft(2, '0');
    final mm = s.minute.toString().padLeft(2, '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시간 슬롯 삭제'),
        content: Text(
          '${s.label} $hh:$mm 슬롯을 삭제할까요?\n예약된 알림도 함께 취소돼요.',
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
    if (ok != true || !context.mounted) return;
    await context.read<SlotsProvider>().remove(s.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.label} 슬롯이 삭제됐어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotsProvider = context.watch<SlotsProvider>();
    final slots = slotsProvider.items;
    final meds = context.watch<MedicationsProvider>().items;
    final medsById = {for (final m in meds) m.id: m};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('복용 일정', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: slots.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.x4l,
              ),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (_, i) {
                final s = slots[i];
                final slotMeds = slotsProvider
                    .medicationsFor(s.id)
                    .map((sm) => medsById[sm.medicationId])
                    .whereType<Medication>()
                    .toList();
                return _ScheduleCard(
                  slot: s,
                  meds: slotMeds,
                  daysLabel: _daysLabel(s.daysOfWeek),
                  accent: _dotColor(i),
                  onDelete: () => _confirmDelete(context, s),
                  onEdit: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => SlotFormScreen(
                        existing: s,
                        existingMedicationIds: slotMeds.map((m) => m.id).toList(),
                      )),
                    );
                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('시간 슬롯이 수정됐어요')),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const SlotFormScreen()));
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('새 시간 슬롯이 추가됐어요')),
            );
          }
        },
        label: const Text('새 시간 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Color _dotColor(int i) {
    const palette = [AppColors.pillDeep, AppColors.jade, AppColors.capsule, AppColors.care];
    return palette[i % palette.length];
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_outlined, size: 48, color: AppColors.inkMute),
              const SizedBox(height: AppSpacing.md),
              const Text('등록된 일정이 없어요',
                  style: TextStyle(fontSize: 16, color: AppColors.ink2)),
            ],
          ),
        ),
      );
}

class _ScheduleCard extends StatelessWidget {
  final TimeSlot slot;
  final List<Medication> meds;
  final String daysLabel;
  final Color accent;
  final VoidCallback onDelete, onEdit;

  const _ScheduleCard({
    required this.slot,
    required this.meds,
    required this.daysLabel,
    required this.accent,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hh = slot.hour.toString().padLeft(2, '0');
    final mm = slot.minute.toString().padLeft(2, '0');
    final names = meds.isEmpty ? '약 미지정' : meds.map((m) => m.name).join(', ');
    final photo = meds
        .map((m) => m.photoPath)
        .where((p) => p != null && File(p).existsSync())
        .firstOrNull;
    final tint = AppColors.fromHex(meds.isEmpty ? null : meds.first.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x12000000)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlAll,
        child: InkWell(
          borderRadius: AppRadius.xlAll,
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 점 + 요일 + 삭제
                Row(
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.sm),
                    Text(daysLabel,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink2,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.cancel_outlined, size: 22, color: AppColors.inkMute),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1),
                ),
                // 약 정보
                Row(
                  children: [
                    _PillAvatar(photoPath: photo, tint: tint),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(names,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink,
                              )),
                          const SizedBox(height: 2),
                          Text('${meds.length}개',
                              style: const TextStyle(fontSize: 14, color: AppColors.inkMute)),
                        ],
                      ),
                    ),
                    _Badge(text: slot.label),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // 시각 + 벨
                Row(
                  children: [
                    Text('$hh:$mm',
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink,
                          letterSpacing: -0.5,
                        )),
                    const Spacer(),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.pillDeep.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          size: 20, color: AppColors.pillDeep),
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

class _PillAvatar extends StatelessWidget {
  final String? photoPath;
  final Color tint;
  const _PillAvatar({this.photoPath, this.tint = AppColors.pillDeep});
  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: Image.file(File(photoPath!), width: 52, height: 52, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.medication_rounded, color: tint, size: 26),
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
        color: AppColors.pillDeep.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(text,
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.pillDeep,
          )),
    );
  }
}

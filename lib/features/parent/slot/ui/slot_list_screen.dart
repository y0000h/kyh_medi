import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../domain/time_slot.dart';
import 'slots_provider.dart';
import 'slot_form_screen.dart';

class SlotListScreen extends StatelessWidget {
  const SlotListScreen({super.key});

  String _daysLabel(int mask) {
    if (mask == 127) return '매일';
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return List.generate(7, (i) => (mask & (1 << i)) != 0 ? labels[i] : null)
        .where((x) => x != null).join(', ');
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
    final slots = context.watch<SlotsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('시간 관리')),
      body: slots.isEmpty
          ? const Center(child: Text('등록된 슬롯이 없어요', style: TextStyle(fontSize: 20)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final s = slots[i];
                final hh = s.hour.toString().padLeft(2, '0');
                final mm = s.minute.toString().padLeft(2, '0');
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: AppShadows.md,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
                    ),
                    title: Text('${s.label} $hh:$mm',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    subtitle: Text(_daysLabel(s.daysOfWeek)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 28),
                      tooltip: '슬롯 삭제',
                      onPressed: () => _confirmDelete(context, s),
                    ),
                  ),
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
}

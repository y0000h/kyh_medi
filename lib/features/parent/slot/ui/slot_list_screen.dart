import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final slots = context.watch<SlotsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('시간 관리')),
      body: slots.isEmpty
          ? const Center(child: Text('등록된 슬롯이 없어요', style: TextStyle(fontSize: 20)))
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = slots[i];
                final hh = s.hour.toString().padLeft(2, '0');
                final mm = s.minute.toString().padLeft(2, '0');
                return Card(child: ListTile(
                  title: Text('${s.label} $hh:$mm',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  subtitle: Text(_daysLabel(s.daysOfWeek)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async => context.read<SlotsProvider>().remove(s.id),
                  ),
                ));
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SlotFormScreen())),
        label: const Text('새 시간 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'parent_detail_provider.dart';

class ParentDetailScreen extends StatelessWidget {
  final String parentDeviceId;
  final String label;

  const ParentDetailScreen({
    super.key,
    required this.parentDeviceId,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentDetailProvider(parentDeviceId)
        ..load()
        ..subscribeRealtime(),
      child: _Body(label: label),
    );
  }
}

class _Body extends StatelessWidget {
  final String label;
  const _Body({required this.label});

  IconData _icon(String s) => switch (s) {
        'taken' => Icons.check_circle,
        'missed' => Icons.cancel,
        _ => Icons.schedule,
      };

  Color _color(String s) => switch (s) {
        'taken' => Colors.green,
        'missed' => Colors.red,
        _ => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'taken' => '복용 완료',
        'missed' => '미복용',
        _ => '대기 중',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentDetailProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('$label 의 오늘')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ParentDetailProvider>().load(),
        child: p.events.isEmpty && !p.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '오늘 아직 등록된 복용 이벤트가 없어요.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: p.events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final e = p.events[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(_icon(e.status),
                          color: _color(e.status), size: 32),
                      title: Text(
                        e.medicationName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_statusLabel(e.status)} · '
                        '${e.occurredAt.toLocal().hour.toString().padLeft(2, '0')}:'
                        '${e.occurredAt.toLocal().minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

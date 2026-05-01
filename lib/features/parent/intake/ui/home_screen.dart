// lib/features/parent/intake/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
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
  }

  Color _statusColor(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return AppColors.jade;
      case DoseEvent.statusMissed: return AppColors.care;
      default: return AppColors.pillDeep;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return '복용 완료';
      case DoseEvent.statusMissed: return '미복용';
      default: return '복용 전';
    }
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
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: today.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = today[i];
                final hh = t.slot.hour.toString().padLeft(2, '0');
                final mm = t.slot.minute.toString().padLeft(2, '0');
                return Card(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => IntakeCheckScreen(slotView: t),
                      ));
                      if (context.mounted) context.read<IntakeProvider>().loadToday();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('$hh:$mm',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(t.slot.label,
                              style: const TextStyle(fontSize: 18, color: AppColors.ink2)),
                        ]),
                        const SizedBox(width: 24),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final m in t.medications)
                              Padding(padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• ${m.name}', style: const TextStyle(fontSize: 18))),
                          ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _statusColor(t.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_statusLabel(t.status),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

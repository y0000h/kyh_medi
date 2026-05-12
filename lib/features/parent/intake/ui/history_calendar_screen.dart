// lib/features/parent/intake/ui/history_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/hive/hive_init.dart';
import '../../../../core/theme/tokens.dart';
import '../../medication/ui/medications_provider.dart';
import '../../monetization/ad_banner.dart';
import '../data/dose_event_repository.dart';
import '../domain/dose_event.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({super.key});
  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<DateTime, List<DoseEvent>> _byDay = {};

  @override
  void initState() {
    super.initState();
    _load(_focused);
  }

  Future<void> _load(DateTime month) async {
    final box = Hive.box<DoseEvent>(HiveInit.doseEventsBox);
    final repo = DoseEventRepository(box);
    final logs = repo.findByMonth(month);
    final map = <DateTime, List<DoseEvent>>{};
    for (final l in logs) {
      final key = DateTime(l.date.year, l.date.month, l.date.day);
      map.putIfAbsent(key, () => []).add(l);
    }
    setState(() => _byDay = map);
  }

  Color? _dayColor(DateTime day) {
    final list = _byDay[DateTime(day.year, day.month, day.day)];
    if (list == null || list.isEmpty) return null;
    if (list.any((l) => l.status == DoseEvent.statusMissed)) return AppColors.care;
    if (list.every((l) => l.status == DoseEvent.statusTaken)) return AppColors.jade;
    return AppColors.inkMute;
  }

  String _statusLabel(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return '복용 완료';
      case DoseEvent.statusMissed: return '미복용';
      default: return '복용 전';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return AppColors.jade;
      case DoseEvent.statusMissed: return AppColors.care;
      default: return AppColors.inkMute;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case DoseEvent.statusTaken: return Icons.check_circle;
      case DoseEvent.statusMissed: return Icons.cancel;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    final medById = {for (final m in meds) m.id: m.name};
    final timeFmt = DateFormat('a h:mm', 'ko_KR');

    final items = _selected == null
        ? const <DoseEvent>[]
        : (_byDay[DateTime(_selected!.year, _selected!.month, _selected!.day)] ?? const []);

    return Scaffold(
      appBar: AppBar(title: const Text('복용 이력')),
      body: Column(children: [
        TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now(),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
          onPageChanged: (foc) => _load(foc),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (_, day, __) {
              final c = _dayColor(day);
              if (c == null) return const SizedBox.shrink();
              return Positioned(bottom: 4,
                child: Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)));
            },
          ),
        ),
        const Divider(),
        if (_selected != null)
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text('이 날의 복용 기록이 없어요',
                          style: TextStyle(fontSize: 16, color: AppColors.inkMute)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final l = items[i];
                      final name = medById[l.medicationId] ?? '삭제된 약';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_statusIcon(l.status), color: _statusColor(l.status), size: 28),
                        title: Text(name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        subtitle: Text(
                          '${timeFmt.format(l.scheduledAt)} · ${_statusLabel(l.status)}',
                          style: const TextStyle(fontSize: 14, color: AppColors.ink2),
                        ),
                      );
                    },
                  ),
          ),
        const AdBanner(),
      ]),
    );
  }
}

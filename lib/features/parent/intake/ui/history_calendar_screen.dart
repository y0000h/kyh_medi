// lib/features/parent/intake/ui/history_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/hive/hive_init.dart';
import '../../../../core/theme/tokens.dart';
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

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: ListView(
            padding: const EdgeInsets.all(AppSizes.padding),
            children: (_byDay[DateTime(_selected!.year, _selected!.month, _selected!.day)] ?? [])
                .map((l) => ListTile(
                      leading: Icon(
                        l.status == DoseEvent.statusTaken ? Icons.check_circle :
                        l.status == DoseEvent.statusMissed ? Icons.cancel : Icons.schedule,
                        color: l.status == DoseEvent.statusTaken ? AppColors.jade :
                               l.status == DoseEvent.statusMissed ? AppColors.care : AppColors.inkMute,
                      ),
                      title: Text('약 ${l.medicationId}'),
                      subtitle: Text(l.scheduledAt.toString()),
                    )).toList(),
          )),
        const AdBanner(),
      ]),
    );
  }
}

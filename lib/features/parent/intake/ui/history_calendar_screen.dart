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
    _selected = DateTime.now();
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
      case DoseEvent.statusTaken: return Icons.check_circle_rounded;
      case DoseEvent.statusMissed: return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    final medById = {for (final m in meds) m.id: m.name};
    final timeFmt = DateFormat('a h:mm', 'ko_KR');
    final dayFmt = DateFormat('M월 d일 (E)', 'ko_KR');

    final items = _selected == null
        ? const <DoseEvent>[]
        : (_byDay[DateTime(_selected!.year, _selected!.month, _selected!.day)] ?? const []);
    final takenCount = items.where((l) => l.status == DoseEvent.statusTaken).length;
    final missedCount = items.where((l) => l.status == DoseEvent.statusMissed).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('복용 이력', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.x4l,
            ),
            children: [
              _calendarCard(),
              const SizedBox(height: AppSpacing.md),
              _legend(),
              const SizedBox(height: AppSpacing.xl),
              if (_selected != null) ...[
                Row(
                  children: [
                    Text(dayFmt.format(_selected!),
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink,
                        )),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Text('복용 $takenCount · 미복용 $missedCount',
                          style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  _emptyDay()
                else
                  ...items.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _logCard(
                          name: medById[l.medicationId] ?? '삭제된 약',
                          subtitle: '${timeFmt.format(l.scheduledAt)} · ${_statusLabel(l.status)}',
                          status: l.status,
                        ),
                      )),
              ],
            ],
          ),
        ),
        const AdBanner(),
      ]),
    );
  }

  Widget _calendarCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x10000000)),
        ],
      ),
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _focused,
        selectedDayPredicate: (d) => isSameDay(_selected, d),
        onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
        onPageChanged: (foc) => _load(foc),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.inkMute),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.inkMute),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMute),
          weekendStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMute),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(fontSize: 15, color: AppColors.ink),
          weekendTextStyle: const TextStyle(fontSize: 15, color: AppColors.ink2),
          todayDecoration: BoxDecoration(
            color: AppColors.pillDeep.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.pillDeep,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.pillDeep,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onPrimary,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (_, day, __) {
            final c = _dayColor(day);
            if (c == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 5,
              child: Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            );
          },
        ),
      ),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppColors.jade, '복용 완료'),
        const SizedBox(width: AppSpacing.lg),
        _legendDot(AppColors.care, '미복용'),
        const SizedBox(width: AppSpacing.lg),
        _legendDot(AppColors.inkMute, '일부'),
      ],
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
      ],
    );
  }

  Widget _logCard({required String name, required String subtitle, required String status}) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDay() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.paper2,
          borderRadius: AppRadius.lgAll,
        ),
        child: const Text('이 날의 복용 기록이 없어요',
            style: TextStyle(fontSize: 15, color: AppColors.inkMute)),
      );
}

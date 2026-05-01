import 'package:hive/hive.dart';
import '../domain/dose_event.dart';

class DoseEventRepository {
  final Box<DoseEvent> _box;
  DoseEventRepository(this._box);

  /// 같은 키 (date|slotId|medicationId)가 있으면 그대로, 없으면 pending으로 생성
  Future<void> upsertPending({
    required String slotId,
    required String medicationId,
    required DateTime scheduledAt,
  }) async {
    final date = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final id = DoseEvent.makeId(date, slotId, medicationId);
    if (_box.containsKey(id)) return;
    await _box.put(id, DoseEvent(
      id: id,
      date: date,
      slotId: slotId,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      status: DoseEvent.statusPending,
      createdAt: DateTime.now(),
    ));
  }

  /// 슬롯 내 모든 약을 taken으로 마킹 (해당 날짜)
  Future<List<DoseEvent>> markSlotTaken({
    required String slotId,
    required DateTime date,
    required DateTime now,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final updated = <DoseEvent>[];
    for (final e in _box.values) {
      if (e.slotId == slotId && _sameDay(e.date, dateOnly)
          && e.status == DoseEvent.statusPending) {
        e.status = DoseEvent.statusTaken;
        e.takenAt = now;
        await e.save();
        updated.add(e);
      }
    }
    return updated;
  }

  /// 30분 지나도 pending인 이벤트를 missed로 마킹. 변경된 이벤트 리스트 반환.
  Future<List<DoseEvent>> markStaleAsMissed({required DateTime now}) async {
    final cutoff = now.subtract(const Duration(minutes: 30));
    final updated = <DoseEvent>[];
    for (final e in _box.values) {
      if (e.status == DoseEvent.statusPending && e.scheduledAt.isBefore(cutoff)) {
        e.status = DoseEvent.statusMissed;
        await e.save();
        updated.add(e);
      }
    }
    return updated;
  }

  List<DoseEvent> findByDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _box.values.where((e) => _sameDay(e.date, d)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<DoseEvent> findByMonth(DateTime monthAnchor) {
    final start = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final end = DateTime(monthAnchor.year, monthAnchor.month + 1, 1);
    return _box.values
        .where((e) => e.date.isAtSameMomentAs(start) ||
            (e.date.isAfter(start) && e.date.isBefore(end)))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Stream<BoxEvent> watch() => _box.watch();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

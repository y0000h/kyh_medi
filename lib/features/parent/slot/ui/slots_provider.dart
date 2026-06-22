import 'package:flutter/foundation.dart';
import '../../../../core/notification/notification_scheduler.dart';
import '../../../../core/notification/notification_service.dart';
import '../data/slot_repository.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotsProvider extends ChangeNotifier {
  final SlotRepository _repo;
  SlotsProvider(this._repo) {
    _items = _repo.findActiveSlots();
  }

  List<TimeSlot> _items = const [];
  List<TimeSlot> get items => _items;

  String _newId() => 'slot-${DateTime.now().millisecondsSinceEpoch}';

  Future<TimeSlot> create({
    required String label,
    required int hour,
    required int minute,
    required int daysOfWeek,
    required List<String> medicationIds,
    bool scheduleAlarm = true,
  }) async {
    final s = TimeSlot(
      id: _newId(), label: label, hour: hour, minute: minute, daysOfWeek: daysOfWeek,
    );
    await _repo.insertSlot(s);
    for (final mid in medicationIds) {
      await _repo.attachMedication(SlotMedication(slotId: s.id, medicationId: mid));
    }
    if (scheduleAlarm) await _scheduleNotifications(s);
    _items = _repo.findActiveSlots();
    notifyListeners();
    // 주: medications 미러는 MedicationsProvider.add 시점에 이미 push됨.
    // 슬롯 ↔ 약 매핑(slot_medications)은 부모 로컬만 (Q3 결정 — Supabase 미러 X).
    return s;
  }

  Future<void> remove(String slotId) async {
    // 데이터 먼저 — 알림 취소가 throw 해도 슬롯 삭제는 보장.
    await _repo.softDeleteSlot(slotId);
    _items = _repo.findActiveSlots();
    notifyListeners();
    // 알림 취소는 best-effort. flutter_local_notifications가 release/R8 환경에서
    // 캐시 역직렬화 실패로 throw하는 케이스가 있어 try/catch로 흡수.
    try {
      final hash = NotificationIdEncoder.hashSlotId(slotId);
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        await NotificationService.cancelMany(
          NotificationIdEncoder.idsForSlotInstance(slotHash: hash, dayOffset: dayOffset),
        );
      }
    } catch (_) {/* swallow */}
  }

  Future<void> _scheduleNotifications(TimeSlot slot) async {
    final hash = NotificationIdEncoder.hashSlotId(slot.id);
    final from = DateTime.now();
    final today0 = DateTime(from.year, from.month, from.day);
    final fireDays = NotificationScheduler.next7DaysFor(slot: slot, from: from);
    for (final day in fireDays) {
      final dayOffset = day.difference(today0).inDays;
      final fires = NotificationScheduler.computeFireTimes(day);
      for (int i = 0; i < fires.length; i++) {
        if (fires[i].isBefore(from)) continue;
        final notifId = NotificationIdEncoder.encode(
          slotHash: hash, dayOffset: dayOffset, retryIndex: i,
        );
        await NotificationService.scheduleAt(
          id: notifId,
          title: '${slot.label} 약 드실 시간이에요',
          body: '${slot.hour.toString().padLeft(2, '0')}:'
                '${slot.minute.toString().padLeft(2, '0')}',
          fireAt: fires[i],
          payload: 'slot:${slot.id}',
        );
      }
    }
  }

  List<SlotMedication> medicationsFor(String slotId) =>
      _repo.findMedicationsForSlot(slotId);
}

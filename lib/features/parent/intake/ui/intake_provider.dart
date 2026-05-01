import 'package:flutter/foundation.dart';
import '../../medication/data/medication_repository.dart';
import '../../medication/domain/medication.dart';
import '../../slot/data/slot_repository.dart';
import '../../slot/domain/time_slot.dart';
import '../data/dose_event_repository.dart';
import '../domain/dose_event.dart';

class TodaySlotView {
  final TimeSlot slot;
  final List<Medication> medications;
  final String status; // pending / taken / missed
  final DateTime scheduledAt;

  TodaySlotView({
    required this.slot,
    required this.medications,
    required this.status,
    required this.scheduledAt,
  });
}

class IntakeProvider extends ChangeNotifier {
  final DoseEventRepository _doseRepo;
  final SlotRepository _slotRepo;
  final MedicationRepository _medRepo;

  /// missed 이벤트 콜백 (Phase 7에서 SupabaseSync 연결)
  void Function(List<DoseEvent>)? onMissed;
  /// taken 이벤트 콜백 (Phase 7에서 SupabaseSync 연결)
  void Function(List<DoseEvent>)? onTaken;

  IntakeProvider(this._doseRepo, this._slotRepo, this._medRepo);

  List<TodaySlotView> _today = const [];
  List<TodaySlotView> get today => _today;

  Future<void> loadToday() async {
    final now = DateTime.now();
    // 1) 오래된 pending → missed
    final missed = await _doseRepo.markStaleAsMissed(now: now);
    if (missed.isNotEmpty) onMissed?.call(missed);

    // 2) 오늘 활성 슬롯
    final slots = _slotRepo.findActiveSlots();
    final today0 = DateTime(now.year, now.month, now.day);
    final result = <TodaySlotView>[];

    for (final slot in slots) {
      final bit = 1 << (today0.weekday - 1);
      if ((slot.daysOfWeek & bit) == 0) continue;

      final scheduled = DateTime(today0.year, today0.month, today0.day,
          slot.hour, slot.minute);

      // 슬롯의 약들
      final slotMeds = _slotRepo.findMedicationsForSlot(slot.id);
      final meds = <Medication>[];
      for (final sm in slotMeds) {
        final m = _medRepo.findById(sm.medicationId);
        if (m != null && m.deletedAt == null) meds.add(m);
      }
      if (meds.isEmpty) continue;

      // 각 약에 pending 보장
      for (final m in meds) {
        await _doseRepo.upsertPending(
          slotId: slot.id, medicationId: m.id, scheduledAt: scheduled,
        );
      }

      // 슬롯 전체 상태 집계
      final logs = _doseRepo.findByDate(today0);
      final logsForSlot = logs.where((l) =>
          l.slotId == slot.id && l.scheduledAt == scheduled).toList();
      final status = _aggregateStatus(logsForSlot);

      result.add(TodaySlotView(
        slot: slot, medications: meds, status: status, scheduledAt: scheduled,
      ));
    }

    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    _today = result;
    notifyListeners();
  }

  String _aggregateStatus(List<DoseEvent> logs) {
    if (logs.every((l) => l.status == DoseEvent.statusTaken)) return DoseEvent.statusTaken;
    if (logs.any((l) => l.status == DoseEvent.statusMissed)) return DoseEvent.statusMissed;
    return DoseEvent.statusPending;
  }

  Future<void> markSlotTaken(String slotId, DateTime date) async {
    final taken = await _doseRepo.markSlotTaken(
      slotId: slotId, date: date, now: DateTime.now(),
    );
    if (taken.isNotEmpty) onTaken?.call(taken);
    await loadToday();
  }
}

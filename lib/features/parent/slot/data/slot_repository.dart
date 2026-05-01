import 'package:hive/hive.dart';
import '../domain/time_slot.dart';
import '../domain/slot_medication.dart';

class SlotRepository {
  final Box<TimeSlot> _slots;
  final Box<SlotMedication> _slotMeds;
  SlotRepository(this._slots, this._slotMeds);

  Future<void> insertSlot(TimeSlot s) async => _slots.put(s.id, s);

  Future<void> updateSlot(TimeSlot s) async => _slots.put(s.id, s);

  List<TimeSlot> findActiveSlots() => _slots.values
      .where((s) => s.deletedAt == null && s.enabled)
      .toList()
    ..sort((a, b) {
      final cmp = a.hour.compareTo(b.hour);
      return cmp != 0 ? cmp : a.minute.compareTo(b.minute);
    });

  TimeSlot? findSlotById(String id) => _slots.get(id);

  Future<void> softDeleteSlot(String id) async {
    final s = _slots.get(id);
    if (s == null) return;
    s.deletedAt = DateTime.now();
    await s.save();
    // 연결된 SlotMedication도 모두 detach
    final keysToDelete = _slotMeds.values
        .where((sm) => sm.slotId == id)
        .map((sm) => sm.compoundKey)
        .toList();
    for (final k in keysToDelete) {
      await _slotMeds.delete(k);
    }
  }

  Future<void> attachMedication(SlotMedication sm) async =>
      _slotMeds.put(sm.compoundKey, sm);

  Future<void> detachMedication(String slotId, String medicationId) async =>
      _slotMeds.delete('$slotId|$medicationId');

  List<SlotMedication> findMedicationsForSlot(String slotId) =>
      _slotMeds.values.where((sm) => sm.slotId == slotId).toList();
}

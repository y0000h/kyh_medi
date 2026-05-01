import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/slot/data/slot_repository.dart';
import 'package:kyh_medi/features/parent/slot/domain/time_slot.dart';
import 'package:kyh_medi/features/parent/slot/domain/slot_medication.dart';

void main() {
  late Directory tempDir;
  late Box<TimeSlot> slots;
  late Box<SlotMedication> slotMeds;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TimeSlotAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SlotMedicationAdapter());
    final ts = DateTime.now().microsecondsSinceEpoch;
    slots = await Hive.openBox<TimeSlot>('slots_$ts');
    slotMeds = await Hive.openBox<SlotMedication>('slotmeds_$ts');
  });

  tearDown(() async {
    await slots.close();
    await slotMeds.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('insertSlot + findActiveSlots', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    final all = repo.findActiveSlots();
    expect(all, hasLength(1));
    expect(all.first.label, '아침');
  });

  test('attachMedication + findMedicationsForSlot', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    await repo.attachMedication(SlotMedication(slotId: 'slot-1', medicationId: 'med-1'));
    final meds = repo.findMedicationsForSlot('slot-1');
    expect(meds, hasLength(1));
    expect(meds.first.medicationId, 'med-1');
  });

  test('softDeleteSlot also detaches all medications', () async {
    final repo = SlotRepository(slots, slotMeds);
    await repo.insertSlot(TimeSlot(
      id: 'slot-1', label: '아침', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday,
    ));
    await repo.attachMedication(SlotMedication(slotId: 'slot-1', medicationId: 'med-1'));
    await repo.softDeleteSlot('slot-1');
    expect(repo.findActiveSlots(), isEmpty);
    expect(repo.findMedicationsForSlot('slot-1'), isEmpty);
  });
}

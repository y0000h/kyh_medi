import 'package:hive/hive.dart';

part 'slot_medication.g.dart';

@HiveType(typeId: 2)
class SlotMedication extends HiveObject {
  @HiveField(0) String slotId;
  @HiveField(1) String medicationId;
  @HiveField(2) int doseCount;

  SlotMedication({
    required this.slotId,
    required this.medicationId,
    this.doseCount = 1,
  });

  /// Hive 키: "{slotId}|{medicationId}"
  String get compoundKey => '$slotId|$medicationId';
}

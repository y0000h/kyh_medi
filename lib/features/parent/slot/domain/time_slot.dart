import 'package:hive/hive.dart';

part 'time_slot.g.dart';

@HiveType(typeId: 1)
class TimeSlot extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String label;         // "아침"
  @HiveField(2) int hour;             // 0-23
  @HiveField(3) int minute;           // 0-59
  @HiveField(4) int daysOfWeek;       // 비트마스크: 월=1, 화=2, ..., 일=64
  @HiveField(5) bool enabled;
  @HiveField(6) DateTime? deletedAt;

  TimeSlot({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.enabled = true,
    this.deletedAt,
  });

  static const int everyday = 127; // 월~일 모두
}

import 'package:hive/hive.dart';

part 'dose_event.g.dart';

@HiveType(typeId: 3)
class DoseEvent extends HiveObject {
  @HiveField(0) String id;            // "YYYY-MM-DD|slotId|medicationId"
  @HiveField(1) DateTime date;
  @HiveField(2) String slotId;
  @HiveField(3) String medicationId;
  @HiveField(4) DateTime scheduledAt;
  @HiveField(5) DateTime? takenAt;
  @HiveField(6) String status;        // 'pending' | 'taken' | 'missed' | 'skipped'
  @HiveField(7) DateTime createdAt;

  DoseEvent({
    required this.id,
    required this.date,
    required this.slotId,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.createdAt,
  });

  static const statusPending = 'pending';
  static const statusTaken = 'taken';
  static const statusMissed = 'missed';
  static const statusSkipped = 'skipped';

  static String makeId(DateTime date, String slotId, String medicationId) {
    final ymd = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '$ymd|$slotId|$medicationId';
  }
}

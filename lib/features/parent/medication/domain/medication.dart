import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0) String id;            // UUID
  @HiveField(1) String name;
  @HiveField(2) String? photoPath;    // 부모 로컬만 (Supabase 동기화 X)
  @HiveField(3) String? memo;         // 부모 로컬만
  @HiveField(4) String? colorHex;
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime? deletedAt;
  @HiveField(7) int? mealTiming;      // 0=식전 30분, 1=식후 30분, 2=식후 즉시
  @HiveField(8) String? dose;         // "1캡슐", "3개" 등
  @HiveField(9) DateTime? startDate;  // 복용 시작일
  @HiveField(10) DateTime? endDate;   // 복용 종료일

  Medication({
    required this.id,
    required this.name,
    this.photoPath,
    this.memo,
    this.colorHex,
    required this.createdAt,
    this.deletedAt,
    this.mealTiming,
    this.dose,
    this.startDate,
    this.endDate,
  });

  /// 식사시점 라벨.
  static const mealTimingLabels = ['식전 30분', '식후 30분', '식후 즉시'];
  String? get mealTimingLabel =>
      mealTiming == null ? null : mealTimingLabels[mealTiming!.clamp(0, 2)];
}

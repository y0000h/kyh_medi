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

  Medication({
    required this.id,
    required this.name,
    this.photoPath,
    this.memo,
    this.colorHex,
    required this.createdAt,
    this.deletedAt,
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/medication/data/medication_repository.dart';
import 'package:kyh_medi/features/parent/medication/domain/medication.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Box<Medication> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MedicationAdapter());
    box = await Hive.openBox<Medication>(p.join('med_${DateTime.now().microsecondsSinceEpoch}'));
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('insert and findActive returns inserted medication', () async {
    final repo = MedicationRepository(box);
    await repo.insert(Medication(
      id: 'med-1', name: '혈압약', createdAt: DateTime(2026, 5, 1),
    ));
    final all = repo.findActive();
    expect(all, hasLength(1));
    expect(all.first.name, '혈압약');
  });

  test('softDelete excludes from findActive', () async {
    final repo = MedicationRepository(box);
    await repo.insert(Medication(
      id: 'med-2', name: '비타민', createdAt: DateTime(2026, 5, 1),
    ));
    await repo.softDelete('med-2');
    expect(repo.findActive(), isEmpty);
    expect(repo.findById('med-2')?.deletedAt, isNotNull);
  });
}

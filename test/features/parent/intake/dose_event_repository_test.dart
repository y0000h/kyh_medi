import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kyh_medi/features/parent/intake/data/dose_event_repository.dart';
import 'package:kyh_medi/features/parent/intake/domain/dose_event.dart';

void main() {
  late Directory tempDir;
  late Box<DoseEvent> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DoseEventAdapter());
    box = await Hive.openBox<DoseEvent>('doses_${DateTime.now().microsecondsSinceEpoch}');
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('upsertPending creates new event if missing', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs, hasLength(1));
    expect(logs.first.status, DoseEvent.statusPending);
  });

  test('markSlotTaken flips status to taken', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    await repo.markSlotTaken(
      slotId: 'slot-1', date: DateTime(2026, 5, 1), now: DateTime(2026, 5, 1, 8, 2),
    );
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, DoseEvent.statusTaken);
    expect(logs.first.takenAt, isNotNull);
  });

  test('markStaleAsMissed flips pending older than 30min to missed', () async {
    final repo = DoseEventRepository(box);
    final scheduled = DateTime(2026, 5, 1, 8, 0);
    await repo.upsertPending(
      slotId: 'slot-1', medicationId: 'med-1', scheduledAt: scheduled,
    );
    await repo.markStaleAsMissed(now: DateTime(2026, 5, 1, 8, 31));
    final logs = repo.findByDate(DateTime(2026, 5, 1));
    expect(logs.first.status, DoseEvent.statusMissed);
  });
}

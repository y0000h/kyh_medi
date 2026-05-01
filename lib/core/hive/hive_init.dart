import 'package:hive_flutter/hive_flutter.dart';

/// Hive 박스 셋업 헬퍼.
///
/// 어댑터 등록 + 박스 open은 Phase 1 (모델 정의 + build_runner)에서
/// 이 함수에 라인 추가됨.
class HiveInit {
  static const medicationsBox = 'medicationsBox';
  static const slotsBox = 'slotsBox';
  static const slotMedicationsBox = 'slotMedicationsBox';
  static const doseEventsBox = 'doseEventsBox';
  static const settingsBox = 'settingsBox';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    // ▼▼ Phase 1에서 다음 라인들 추가 ▼▼
    // Hive.registerAdapter(MedicationAdapter());
    // Hive.registerAdapter(TimeSlotAdapter());
    // Hive.registerAdapter(SlotMedicationAdapter());
    // Hive.registerAdapter(DoseEventAdapter());
    // Hive.registerAdapter(AppSettingsAdapter());
    //
    // await Hive.openBox<Medication>(medicationsBox);
    // await Hive.openBox<TimeSlot>(slotsBox);
    // await Hive.openBox<SlotMedication>(slotMedicationsBox);
    // await Hive.openBox<DoseEvent>(doseEventsBox);
    // await Hive.openBox<AppSettings>(settingsBox);
    // ▲▲
  }
}

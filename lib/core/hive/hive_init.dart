import 'package:hive_flutter/hive_flutter.dart';
import '../../features/parent/medication/domain/medication.dart';
import '../../features/parent/slot/domain/time_slot.dart';
import '../../features/parent/slot/domain/slot_medication.dart';
import '../../features/parent/intake/domain/dose_event.dart';
import '../../features/parent/settings/domain/app_settings.dart';

class HiveInit {
  static const medicationsBox = 'medicationsBox';
  static const slotsBox = 'slotsBox';
  static const slotMedicationsBox = 'slotMedicationsBox';
  static const doseEventsBox = 'doseEventsBox';
  static const settingsBox = 'settingsBox';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicationAdapter());
    Hive.registerAdapter(TimeSlotAdapter());
    Hive.registerAdapter(SlotMedicationAdapter());
    Hive.registerAdapter(DoseEventAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    await Hive.openBox<Medication>(medicationsBox);
    await Hive.openBox<TimeSlot>(slotsBox);
    await Hive.openBox<SlotMedication>(slotMedicationsBox);
    await Hive.openBox<DoseEvent>(doseEventsBox);
    await Hive.openBox<AppSettings>(settingsBox);
  }
}

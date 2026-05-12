import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'core/hive/hive_init.dart';
import 'core/supabase/parent_sync_service.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/caregiver_theme.dart';
import 'core/theme/senior_theme.dart';
import 'features/child/child_shell.dart';
import 'features/mode_select/mode_select_screen.dart';
import 'features/parent/intake/data/dose_event_repository.dart';
import 'features/parent/intake/domain/dose_event.dart';
import 'features/parent/intake/ui/intake_provider.dart';
import 'features/parent/medication/data/medication_repository.dart';
import 'features/parent/medication/domain/medication.dart';
import 'features/parent/medication/ui/medications_provider.dart';
import 'features/parent/monetization/ads_provider.dart';
import 'features/parent/onboarding/onboarding_screen.dart';
import 'features/parent/pairing/ui/pairing_provider.dart';
import 'features/parent/parent_shell.dart';
import 'features/parent/settings/data/settings_repository.dart';
import 'features/parent/settings/domain/app_settings.dart';
import 'features/parent/slot/data/slot_repository.dart';
import 'features/parent/slot/domain/slot_medication.dart';
import 'features/parent/slot/domain/time_slot.dart';
import 'features/parent/slot/ui/slots_provider.dart';

/// 루트 위젯. 사용자 모드(부모/자녀/미선택)에 따라 다른 트리를 빌드한다.
class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // null = 아직 모드 미선택, 'parent' 또는 'child'
  String? _mode;
  bool _onboardingDone = false;
  late final SettingsRepository _settingsRepo;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box<AppSettings>(HiveInit.settingsBox);
    _settingsRepo = SettingsRepository(settingsBox);
    final s = _settingsRepo.current;
    _mode = s.userMode.isEmpty ? null : s.userMode;
    _onboardingDone = s.onboardingDone;
  }

  void _selectMode(String m) {
    setState(() => _mode = m);
  }

  void _completeOnboarding() => setState(() => _onboardingDone = true);

  /// 모드 변경 — 모드 선택 화면으로 다시. 자녀가 로그인 상태이면 Supabase signOut도 같이.
  Future<void> _resetMode() async {
    if (SupabaseInit.client.auth.currentUser != null) {
      await SupabaseInit.client.auth.signOut();
    }
    await _settingsRepo.setUserMode('');
    if (mounted) setState(() => _mode = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return MaterialApp(
        theme: SeniorTheme.light(),
        home: ModeSelectScreen(onSelected: _selectMode),
      );
    }
    if (_mode == AppSettings.modeParent) {
      return _parentApp();
    }
    return _childApp();
  }

  /// 부모 모드: Provider 4종 주입 + 온보딩/메인 셸 분기
  Widget _parentApp() {
    final medRepo = MedicationRepository(Hive.box<Medication>(HiveInit.medicationsBox));
    final slotRepo = SlotRepository(
      Hive.box<TimeSlot>(HiveInit.slotsBox),
      Hive.box<SlotMedication>(HiveInit.slotMedicationsBox),
    );
    final doseRepo = DoseEventRepository(Hive.box<DoseEvent>(HiveInit.doseEventsBox));

    // 페어링 안 된 부모는 sync.* 호출이 모두 no-op이라 안전.
    final sync = ParentSyncService();
    final intakeProvider = IntakeProvider(doseRepo, slotRepo, medRepo)
      ..onMissed = (events) {
        for (final e in events) {
          sync.insertDoseEvent(e);
        }
      }
      ..onTaken = (events) {
        for (final e in events) {
          sync.insertDoseEvent(e);
        }
      };

    return MultiProvider(
      providers: [
        Provider.value(value: sync),
        ChangeNotifierProvider(create: (_) => MedicationsProvider(medRepo, sync: sync)),
        ChangeNotifierProvider(create: (_) => SlotsProvider(slotRepo)),
        ChangeNotifierProvider.value(value: intakeProvider),
        ChangeNotifierProvider(create: (_) => AdsProvider(_settingsRepo)..init()),
        ChangeNotifierProvider(create: (_) => PairingProvider()),
      ],
      child: MaterialApp(
        title: 'KYH 약 알림',
        theme: SeniorTheme.light(),
        home: _onboardingDone
            ? ParentShell(onModeChange: _resetMode)
            : OnboardingScreen(onDone: _completeOnboarding),
      ),
    );
  }

  /// 자녀 모드: Phase 9에서 본격 구현 (현재는 stub)
  Widget _childApp() {
    return MaterialApp(
      title: 'KYH 약 알림 (자녀)',
      theme: CaregiverTheme.light(),
      home: ChildShell(onModeChange: _resetMode),
    );
  }
}

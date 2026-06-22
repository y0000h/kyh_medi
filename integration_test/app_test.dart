// 출시 전 최종 기능 통합 테스트.
//
// 실제 기기(Android 에뮬레이터 / iOS 시뮬레이터)에서 앱 위젯 트리를 띄우고
// 부모 모드의 핵심 사용자 흐름을 단계별로 구동하며 예외/레이아웃/네비게이션
// 오류를 검출한다. 외부 인증(자녀 OTP/Google)·결제는 네트워크가 필요하므로
// 화면 렌더 + 입력 검증까지만 확인한다.
//
// 실행:
//   flutter test integration_test/app_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:kyh_medi/app.dart';
import 'package:kyh_medi/shared/widgets/floating_nav_bar.dart';
import 'package:kyh_medi/core/firebase/fcm_message_handler.dart';
import 'package:kyh_medi/core/firebase/firebase_init.dart';
import 'package:kyh_medi/core/hive/hive_init.dart';
import 'package:kyh_medi/core/notification/notification_service.dart';
import 'package:kyh_medi/core/supabase/supabase_init.dart';
import 'package:kyh_medi/core/time/timezone_init.dart';
import 'package:kyh_medi/features/parent/intake/domain/dose_event.dart';
import 'package:kyh_medi/features/parent/medication/domain/medication.dart';
import 'package:kyh_medi/features/parent/settings/data/settings_repository.dart';
import 'package:kyh_medi/features/parent/settings/domain/app_settings.dart';
import 'package:kyh_medi/features/parent/slot/domain/slot_medication.dart';
import 'package:kyh_medi/features/parent/slot/domain/time_slot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // main()과 동일한 인프라 초기화 (Firebase/AdMob은 best-effort).
  Future<void> initInfra() async {
    initializeTimezone();
    await initializeDateFormatting('ko_KR', null);
    await HiveInit.initialize();
    try {
      await SupabaseInit.initialize();
    } catch (_) {}
    try {
      await FirebaseInit.initialize();
      await FcmMessageHandler.initialize();
    } catch (_) {}
    await NotificationService.initialize();
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }

  Future<void> clearData() async {
    await Hive.box<Medication>(HiveInit.medicationsBox).clear();
    await Hive.box<TimeSlot>(HiveInit.slotsBox).clear();
    await Hive.box<SlotMedication>(HiveInit.slotMedicationsBox).clear();
    await Hive.box<DoseEvent>(HiveInit.doseEventsBox).clear();
  }

  Future<void> seedMode(String mode) async {
    final settings =
        SettingsRepository(Hive.box<AppSettings>(HiveInit.settingsBox));
    await settings.setUserMode(mode);
    await settings.setOnboardingDone(true);
    await settings.setAdsRemoved(true); // 광고 로딩이 pumpAndSettle을 막지 않도록
  }

  // 스크롤 가능한 위젯이면 보이게 한 뒤 탭. 아니면 그대로 탭.
  Future<void> safeTap(WidgetTester t, Finder f) async {
    try {
      await t.ensureVisible(f);
    } catch (_) {}
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  // FloatingNavBar 안의 라벨로 탭 (다른 곳의 동일 텍스트와 충돌 방지).
  Future<void> tapNav(WidgetTester t, String label) async {
    final f = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.text(label),
    );
    await t.tap(f);
    await t.pumpAndSettle();
  }

  // 약 등록 3단계 마법사: 정보입력(이름) → 복용기간(다음) → 복용시간(저장)
  Future<void> addMedViaWizard(WidgetTester t, String name) async {
    await safeTap(t, find.text('새 약 추가'));
    expect(find.text('정보 입력'), findsOneWidget);
    await t.enterText(find.byType(TextField).at(0), name); // 약 이름
    await t.pumpAndSettle();
    await safeTap(t, find.text('다음')); // → 복용 기간 설정
    expect(find.text('복용 기간 설정'), findsOneWidget);
    await safeTap(t, find.text('다음')); // → 복용 시간 설정
    expect(find.text('복용 시간 설정'), findsOneWidget);
    await safeTap(t, find.text('저장')); // 생성 (약 + 시각 슬롯)
  }

  setUpAll(() async {
    await initInfra();
  });

  testWidgets(
    '부모 모드 전체 흐름: 약 등록(마법사) → 오늘 체크 → 일정 → 이력 → 설정',
    (tester) async {
      await clearData();
      await seedMode(AppSettings.modeParent);

      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // ── STEP 1: 홈 진입, 빈 상태 (주간 스트립 + 진행률 카드) ──
      debugPrint('🧪 STEP 1: 홈 화면 진입 + 빈 상태 확인');
      expect(find.text('약을 등록해요'), findsOneWidget);       // 진행률 카드(빈 상태)
      expect(find.text('복용 일정이 없습니다.'), findsOneWidget); // 빈 카드
      debugPrint('✅ STEP 1 통과');

      // ── STEP 2: 약 관리 탭 → 빈 목록 ──
      debugPrint('🧪 STEP 2: 약 관리 탭 → 빈 목록 확인');
      await tapNav(tester, '약 관리');
      expect(find.text('아직 등록된 약이 없어요'), findsOneWidget);
      debugPrint('✅ STEP 2 통과');

      // ── STEP 3: 약 등록 3단계 마법사 (혈압약) ──
      debugPrint('🧪 STEP 3: 약 등록 마법사(정보입력→복용기간→복용시간)');
      await addMedViaWizard(tester, '혈압약');
      expect(find.text('혈압약'), findsWidgets); // 약 관리 목록에 표시
      debugPrint('✅ STEP 3 통과 (혈압약 등록 — 약 + 시각 슬롯 자동 생성)');

      // ── STEP 4: 오늘 탭 → 약 노출 + '먹었어요' 버튼 ──
      debugPrint('🧪 STEP 4: 오늘 화면에 약 노출 확인');
      await tapNav(tester, '오늘');
      expect(find.text('혈압약'), findsWidgets);
      expect(find.text('먹었어요'), findsWidgets); // 복용 전 상태 = 먹었어요 버튼
      debugPrint('✅ STEP 4 통과');

      // ── STEP 5: 약 카드 탭 → 복용 체크 → 복용 완료 → 홈에 '완료' 도장 ──
      debugPrint('🧪 STEP 5: 복용 체크 → 복용 완료 처리');
      await safeTap(tester, find.text('혈압약').first); // 카드 탭 → IntakeCheck
      expect(find.text('복용 완료'), findsWidgets);
      await safeTap(tester, find.text('복용 완료'));
      expect(find.text('완료'), findsWidgets); // 홈 복귀 후 완료 도장
      debugPrint('✅ STEP 5 통과 (복용 완료 반영)');

      // ── STEP 6: 일정(시간) 탭 → 슬롯 카드 노출 ──
      debugPrint('🧪 STEP 6: 복용 일정 화면 렌더 확인');
      await tapNav(tester, '시간');
      expect(find.text('복용 일정'), findsOneWidget);
      expect(find.text('혈압약'), findsWidgets);
      debugPrint('✅ STEP 6 통과');

      // ── STEP 7: 이력 탭 렌더 ──
      debugPrint('🧪 STEP 7: 복용 이력 화면 렌더 확인');
      await tapNav(tester, '이력');
      expect(find.text('복용 이력'), findsOneWidget);
      debugPrint('✅ STEP 7 통과');

      // ── STEP 8: 설정 탭 렌더 + 항목 확인 ──
      debugPrint('🧪 STEP 8: 설정 화면 렌더 + 항목 확인');
      await tapNav(tester, '설정');
      expect(find.text('자녀와 연결'), findsOneWidget);
      expect(find.text('모드 변경'), findsOneWidget);
      expect(find.textContaining('KYH 약 알림'), findsOneWidget);
      debugPrint('✅ STEP 8 통과');

      // ── STEP 9: 모드 변경 다이얼로그 열고 취소 ──
      debugPrint('🧪 STEP 9: 모드 변경 다이얼로그 표시/취소');
      await safeTap(tester, find.text('모드 변경'));
      expect(find.text('변경'), findsOneWidget); // 다이얼로그 확인 버튼
      await safeTap(tester, find.text('취소'));
      debugPrint('✅ STEP 9 통과');

      // ── STEP 10: 약 관리에서 약 삭제 흐름 ──
      debugPrint('🧪 STEP 10: 약 삭제 다이얼로그 → 삭제');
      await tapNav(tester, '약 관리');
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      await safeTap(tester, find.byIcon(Icons.delete_outline).first);
      expect(find.text('약을 삭제할까요?'), findsOneWidget);
      await safeTap(tester, find.text('삭제'));
      debugPrint('✅ STEP 10 통과 (약 삭제 동작)');

      debugPrint('🎉 부모 모드 전체 흐름 테스트 완료 — 예외/오류 없음');
    },
  );

  testWidgets(
    '자녀 모드: 로그인 화면 렌더 + 이메일 입력 검증',
    (tester) async {
      await seedMode(AppSettings.modeChild);

      await tester.pumpWidget(const App());
      // ChildShell의 비동기 초기화(인증/FCM)를 위해 고정 펌프
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      debugPrint('🧪 STEP A: 자녀 로그인 화면 렌더 확인');
      expect(find.text('자녀 로그인'), findsOneWidget);
      debugPrint('✅ STEP A 통과');

      debugPrint('🧪 STEP B: 이메일 탭 → 잘못된 이메일 검증');
      await tester.tap(find.text('이메일'));
      await tester.pumpAndSettle();
      // 이름(0), 이메일(1) 순. 잘못된 이메일 입력
      await tester.enterText(find.byType(TextField).at(1), 'not-an-email');
      await tester.pumpAndSettle();
      await safeTap(tester, find.text('인증번호 받기'));
      expect(find.text('올바른 이메일을 입력해주세요'), findsOneWidget);
      debugPrint('✅ STEP B 통과 (이메일 검증 동작)');

      debugPrint('🎉 자녀 모드 렌더/검증 테스트 완료');
    },
  );
}

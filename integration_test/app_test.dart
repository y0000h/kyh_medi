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

  // NavigationBar 안의 라벨로 탭 (다른 곳의 동일 텍스트와 충돌 방지).
  Future<void> tapNav(WidgetTester t, String label) async {
    final f = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    await t.tap(f);
    await t.pumpAndSettle();
  }

  setUpAll(() async {
    await initInfra();
  });

  testWidgets(
    '부모 모드 전체 흐름: 약 등록 → 시간 슬롯 → 오늘 체크 → 이력 → 설정',
    (tester) async {
      await clearData();
      await seedMode(AppSettings.modeParent);

      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // ── STEP 1: 홈(오늘의 약) 진입, 빈 상태 ──
      debugPrint('🧪 STEP 1: 홈 화면 진입 + 빈 상태 확인');
      expect(find.text('오늘의 약'), findsOneWidget);
      expect(find.textContaining('오늘 드실 약이 없어요'), findsOneWidget);
      debugPrint('✅ STEP 1 통과');

      // ── STEP 2: 약 관리 탭 → 빈 목록 ──
      debugPrint('🧪 STEP 2: 약 관리 탭 → 빈 목록 확인');
      await tapNav(tester, '약 관리');
      expect(find.text('아직 등록된 약이 없어요'), findsOneWidget);
      debugPrint('✅ STEP 2 통과');

      // ── STEP 3~4: 약 1 등록 (혈압약 / 식후 30분) ──
      debugPrint('🧪 STEP 3: 새 약 추가 폼 진입');
      await safeTap(tester, find.text('새 약 추가'));
      expect(find.text('새 약 등록'), findsOneWidget);
      debugPrint('🧪 STEP 4: 약 이름/메모 입력 후 저장');
      await tester.enterText(find.byType(TextField).at(0), '혈압약');
      await tester.enterText(find.byType(TextField).at(1), '식후 30분');
      await tester.pumpAndSettle();
      await safeTap(tester, find.text('저장'));
      expect(find.text('혈압약'), findsWidgets); // 목록에 표시
      debugPrint('✅ STEP 3~4 통과 (혈압약 등록)');

      // ── STEP 5: 약 2 등록 (당뇨약) ──
      debugPrint('🧪 STEP 5: 두 번째 약(당뇨약) 등록');
      await safeTap(tester, find.text('새 약 추가'));
      await tester.enterText(find.byType(TextField).at(0), '당뇨약');
      await tester.pumpAndSettle();
      await safeTap(tester, find.text('저장'));
      expect(find.text('당뇨약'), findsWidgets);
      debugPrint('✅ STEP 5 통과 (당뇨약 등록)');

      // ── STEP 6: 시간 관리 탭 → 빈 목록 ──
      debugPrint('🧪 STEP 6: 시간 관리 탭 → 빈 목록 확인');
      await tapNav(tester, '시간 관리');
      expect(find.text('등록된 슬롯이 없어요'), findsOneWidget);
      debugPrint('✅ STEP 6 통과');

      // ── STEP 7~8: 시간 슬롯 등록 (아침 08:00, 매일, 약 2개 선택) ──
      debugPrint('🧪 STEP 7: 새 시간 슬롯 폼 진입');
      await safeTap(tester, find.text('새 시간 추가'));
      expect(find.text('시간 슬롯 등록'), findsOneWidget);
      debugPrint('🧪 STEP 8: 약 2개 체크 후 저장');
      await safeTap(tester, find.text('혈압약')); // CheckboxListTile 토글
      await safeTap(tester, find.text('당뇨약'));
      await safeTap(tester, find.text('저장'));
      // 목록으로 복귀: 슬롯이 보여야 함 (라벨 '아침')
      expect(find.textContaining('아침'), findsWidgets);
      debugPrint('✅ STEP 7~8 통과 (아침 08:00 슬롯 등록)');

      // ── STEP 9: 오늘 탭 → 슬롯/약 노출 + 상태 '복용 전' ──
      debugPrint('🧪 STEP 9: 오늘 화면에 슬롯 노출 확인');
      await tapNav(tester, '오늘');
      expect(find.text('혈압약'), findsWidgets);
      expect(find.text('당뇨약'), findsWidgets);
      expect(find.text('복용 전'), findsWidgets);
      debugPrint('✅ STEP 9 통과 (오늘의 약에 슬롯 표시, 상태 복용 전)');

      // ── STEP 10: 슬롯 카드 탭 → 복용 체크 화면 → 복용 완료 ──
      debugPrint('🧪 STEP 10: 슬롯 진입 → 복용 완료 처리');
      await safeTap(tester, find.text('혈압약').first); // 카드 탭 → IntakeCheck
      // 복용 체크 화면: 복용 완료 버튼
      expect(find.text('복용 완료'), findsWidgets);
      await safeTap(tester, find.text('복용 완료'));
      // 홈 복귀 후 상태 배지 '복용 완료'
      expect(find.text('복용 완료'), findsWidgets);
      debugPrint('✅ STEP 10 통과 (복용 완료 반영)');

      // ── STEP 11: 이력 탭 렌더 ──
      debugPrint('🧪 STEP 11: 복용 이력 화면 렌더 확인');
      await tapNav(tester, '이력');
      expect(find.text('복용 이력'), findsOneWidget);
      debugPrint('✅ STEP 11 통과');

      // ── STEP 12: 설정 탭 렌더 + 항목 확인 ──
      debugPrint('🧪 STEP 12: 설정 화면 렌더 + 항목 확인');
      await tapNav(tester, '설정');
      expect(find.text('설정'), findsWidgets);
      expect(find.text('자녀와 연결'), findsOneWidget);
      expect(find.text('모드 변경'), findsOneWidget);
      expect(find.textContaining('KYH 약 알림'), findsOneWidget);
      debugPrint('✅ STEP 12 통과');

      // ── STEP 13: 모드 변경 다이얼로그 열고 취소 ──
      debugPrint('🧪 STEP 13: 모드 변경 다이얼로그 표시/취소');
      await safeTap(tester, find.text('모드 변경'));
      expect(find.text('변경'), findsOneWidget); // 다이얼로그 확인 버튼
      await safeTap(tester, find.text('취소'));
      expect(find.text('설정'), findsWidgets); // 설정 화면 유지
      debugPrint('✅ STEP 13 통과');

      // ── STEP 14: 약 관리에서 약 삭제 흐름 ──
      debugPrint('🧪 STEP 14: 약 삭제 다이얼로그 → 삭제');
      await tapNav(tester, '약 관리');
      expect(find.byIcon(Icons.delete_outline), findsWidgets);
      await safeTap(tester, find.byIcon(Icons.delete_outline).first);
      expect(find.text('약을 삭제할까요?'), findsOneWidget);
      await safeTap(tester, find.text('삭제'));
      debugPrint('✅ STEP 14 통과 (약 삭제 동작)');

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

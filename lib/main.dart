import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/firebase/fcm_message_handler.dart';
import 'core/firebase/firebase_init.dart';
import 'core/hive/hive_init.dart';
import 'core/notification/notification_service.dart';
import 'core/supabase/supabase_init.dart';
import 'core/time/timezone_init.dart';

/// 앱 진입점. 모든 인프라(시간대/날짜 포맷/Hive/Supabase/Firebase/알림/AdMob)를
/// 초기화한 뒤 [App] 위젯을 실행한다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimezone();
  await initializeDateFormatting('ko_KR', null);
  await HiveInit.initialize();
  await SupabaseInit.initialize();
  // Firebase/FCM/AdMob은 Android 전용으로 구성됨 (iOS는 v2). iOS 설정 파일이
  // 없으면 초기화가 예외를 던지므로, 외부 서비스 초기화는 best-effort로 감싸
  // 앱 부팅 자체를 막지 않는다. Android에서는 정상 성공하므로 동작 변화 없음.
  try {
    await FirebaseInit.initialize();
    await FcmMessageHandler.initialize();
  } catch (e) {
    debugPrint('Firebase/FCM 초기화 건너뜀 (플랫폼 미설정): $e');
  }
  await NotificationService.initialize();
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob 초기화 건너뜀 (플랫폼 미설정): $e');
  }
  runApp(const App());
}

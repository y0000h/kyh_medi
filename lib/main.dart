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
  await FirebaseInit.initialize();
  await FcmMessageHandler.initialize();
  await NotificationService.initialize();
  await MobileAds.instance.initialize();
  runApp(const App());
}

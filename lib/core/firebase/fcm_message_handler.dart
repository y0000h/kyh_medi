import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

/// FCM 메시지 진입점.
///
/// - 백그라운드: Firebase가 시스템 알림을 자동 표시. 별도 처리 불필요.
/// - 포그라운드: `flutter_local_notifications`로 강제 헤드업 표시.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class FcmMessageHandler {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForeground);
  }

  static Future<void> _onForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kyh_medi_caregiver',
          '자녀 알림',
          channelDescription: '부모 미복용 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

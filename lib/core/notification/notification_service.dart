// lib/core/notification/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'kyh_medi_alerts';
  static const _channelName = '약 알림';
  static const _channelDesc = '복약 시간 알림';

  static void Function(String payload)? onTap;

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && onTap != null) onTap!(payload);
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId, _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );
  }

  static Future<bool> requestPermissions() async {
    final notif = await Permission.notification.request();
    return notif.isGranted;
  }

  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id);

  static Future<void> cancelMany(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}

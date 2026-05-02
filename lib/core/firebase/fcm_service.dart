import 'package:firebase_messaging/firebase_messaging.dart';
import '../supabase/supabase_init.dart';

/// 자녀 디바이스 FCM 토큰을 `child_users.fcm_token`에 upsert.
///
/// ChildShell이 로그인 직후/최초 진입 시 호출. 토큰 갱신(`onTokenRefresh`)도
/// 자동으로 따라간다.
class FcmService {
  static Future<void> registerForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await messaging.getToken();
    if (token == null) return;
    await _saveToken(token);

    messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String token) async {
    final user = SupabaseInit.client.auth.currentUser;
    if (user == null) return;
    await SupabaseInit.client.from('child_users').upsert({
      'id': user.id,
      'fcm_token': token,
    });
  }
}

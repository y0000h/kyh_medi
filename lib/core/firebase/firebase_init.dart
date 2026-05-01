import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Firebase Core 초기화. main()에서 한 번 호출.
///
/// FCM 토큰 등록 + 메시지 핸들러는 Phase 11에서 별도 service로 추가.
class FirebaseInit {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

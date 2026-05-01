import 'package:hive/hive.dart';
import '../hive/hive_init.dart';
import '../../features/parent/settings/data/settings_repository.dart';
import '../../features/parent/settings/domain/app_settings.dart';
import 'supabase_init.dart';

/// 부모 폰의 Supabase 익명 인증 헬퍼.
///
/// 자녀와 페어링한 부모만 Supabase에 접근. 페어링 시작 시점에 [ensureSignedIn]을
/// 호출하면 anonymous user로 가입 후 `parent_devices`에 본인 row를 만들고
/// `settings.pairedSupabaseUserId`에 user_id를 캐싱한다.
class ParentAnonymousAuth {
  /// 페어링 시작 시점에 호출. 이미 가입돼 있으면 그대로 두고, 없으면 anonymous sign-in.
  /// 성공 시 [SettingsRepository]에 user.id 저장 후 user.id 반환.
  static Future<String> ensureSignedIn() async {
    final settings = SettingsRepository(
      Hive.box<AppSettings>(HiveInit.settingsBox),
    );
    final cached = settings.current.pairedSupabaseUserId;
    final session = SupabaseInit.client.auth.currentSession;

    if (cached != null && session != null && session.user.id == cached) {
      return cached;
    }

    final res = await SupabaseInit.client.auth.signInAnonymously();
    final uid = res.user?.id;
    if (uid == null) {
      throw StateError('anonymous sign-in failed: user is null');
    }

    // parent_devices 테이블에 본인 row 생성 (RLS: user_id == auth.uid()만 허용)
    await SupabaseInit.client.from('parent_devices').upsert({
      'id': uid,
      'device_label': null,
    });

    await settings.setPairedSupabaseUserId(uid);
    return uid;
  }

  /// 페어링 모두 해제 시 호출 (옵션). 기본은 보존하는 정책.
  static Future<void> signOut() async {
    await SupabaseInit.client.auth.signOut();
    final settings = SettingsRepository(Hive.box<AppSettings>(HiveInit.settingsBox));
    await settings.setPairedSupabaseUserId(null);
  }
}

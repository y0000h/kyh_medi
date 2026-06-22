import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_init.dart';

/// 자녀 인증 헬퍼.
///
/// - Google OAuth: 인앱 브라우저 → Supabase 콜백 → 딥링크(`kyhmedi://auth-callback`)로
///   앱 복귀.
/// - 이메일/비밀번호: 폴백.
/// - 가입/로그인 직후 `child_users` 테이블에 본인 row를 보장(upsert).
class ChildAuthService {
  Future<void> signInWithGoogle() async {
    await SupabaseInit.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'kyhmedi://auth-callback',
    );
  }

  /// 이메일로 6자리 OTP 요청. Supabase Auth가 메일로 코드 + 매직 링크 발송.
  /// `shouldCreateUser: true` → 처음 보는 이메일이면 계정 자동 생성.
  /// `emailRedirectTo` → 사용자가 메일의 링크 클릭하면 이 deep link로 앱이 열리며 자동 로그인.
  ///
  /// 이메일 본문에 6자리 코드를 표시하려면 Supabase Dashboard → Auth → Email Templates →
  /// "Magic Link" 템플릿을 `{{ .Token }}` 변수가 보이는 형태로 갱신해야 함
  /// (기본 템플릿은 링크만 노출). README 또는 docs 참조.
  Future<void> sendEmailOtp({
    required String email,
    String? displayName,
  }) async {
    await SupabaseInit.client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      emailRedirectTo: 'kyhmedi://auth-callback',
      data: displayName != null && displayName.isNotEmpty
          ? {'display_name': displayName}
          : null,
    );
  }

  /// 메일로 받은 6자리 코드 검증. 성공 시 세션이 발급되고 onAuthStateChange가 fire.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return SupabaseInit.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// 가입/로그인 후 child_users 테이블에 본인 row 보장.
  Future<void> ensureChildUserRow({String? displayName}) async {
    final user = SupabaseInit.client.auth.currentUser;
    if (user == null) return;
    await SupabaseInit.client.from('child_users').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': displayName?.isNotEmpty == true
          ? displayName
          : (user.userMetadata?['display_name'] ?? user.email),
    });
  }

  // local scope: 서버 로그아웃 URL을 브라우저로 열지 않고 기기 세션만 종료
  // (global 기본값은 iOS에서 빈 Safari 페이지가 잠깐 뜸).
  Future<void> signOut() =>
      SupabaseInit.client.auth.signOut(scope: SignOutScope.local);

  Stream<AuthState> get onAuthStateChange =>
      SupabaseInit.client.auth.onAuthStateChange;

  User? get currentUser => SupabaseInit.client.auth.currentUser;
}

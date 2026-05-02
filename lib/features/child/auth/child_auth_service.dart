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

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return SupabaseInit.client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName ?? ''},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return SupabaseInit.client.auth.signInWithPassword(
      email: email,
      password: password,
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

  Future<void> signOut() => SupabaseInit.client.auth.signOut();

  Stream<AuthState> get onAuthStateChange =>
      SupabaseInit.client.auth.onAuthStateChange;

  User? get currentUser => SupabaseInit.client.auth.currentUser;
}

/// Supabase 프로젝트 연결 정보.
///
/// anon public key는 RLS로 보호되어 클라이언트 노출 안전.
/// service_role key는 절대 클라이언트에 넣지 않음 (Edge Function에서만 사용).
///
/// 빌드 시 `--dart-define=SUPABASE_URL=...`로 덮어쓰기 가능.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://evkuwuyxqyjmaargifnx.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2a3V3dXl4cXlqbWFhcmdpZm54Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NjUwMzUsImV4cCI6MjA5MzE0MTAzNX0.JX1SXPogrFTqAEYqlXtQKZC7kvQNLujQNwXZfvH8bsM',
  );
}

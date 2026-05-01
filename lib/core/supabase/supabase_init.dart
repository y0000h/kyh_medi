import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Supabase Client 초기화 + 전역 접근.
///
/// main()에서 한 번 initialize() 호출. 그 후 SupabaseInit.client로 사용.
class SupabaseInit {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

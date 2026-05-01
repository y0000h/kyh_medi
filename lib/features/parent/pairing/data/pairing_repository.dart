import '../../../../core/supabase/parent_anonymous_auth.dart';
import '../../../../core/supabase/supabase_init.dart';

/// 자녀와 연결된 페어링 한 건의 메타. 부모 측 화면에서 표시용.
class PairingInfo {
  final String pairingId;
  final String childUserId;
  final String? childDisplayName;
  final String? parentLabel;
  final DateTime pairedAt;

  PairingInfo({
    required this.pairingId,
    required this.childUserId,
    required this.childDisplayName,
    required this.parentLabel,
    required this.pairedAt,
  });
}

/// 부모 측 페어링 RPC 래퍼.
///
/// `create_pairing_code`/`pairings`/`child_users` 모두 RLS는 `auth.uid()` 기준이라
/// `ParentAnonymousAuth.ensureSignedIn()`을 먼저 보장해야 한다.
class PairingRepository {
  /// 부모 6자리 코드 발급 (10분 TTL).
  /// 호출 전 anonymous 가입 보장 — 부모가 처음 자녀와 연결할 때 가입 트리거 시점.
  Future<String> createCode() async {
    await ParentAnonymousAuth.ensureSignedIn();
    final res = await SupabaseInit.client.rpc('create_pairing_code');
    return res as String;
  }

  /// 부모 측: 본인 페어링 목록 조회.
  Future<List<PairingInfo>> listMine() async {
    final uid = SupabaseInit.client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await SupabaseInit.client
        .from('pairings')
        .select('id, child_user_id, parent_label, paired_at, child_users(display_name)')
        .eq('parent_device_id', uid);
    return (rows as List)
        .map((r) => PairingInfo(
              pairingId: r['id'] as String,
              childUserId: r['child_user_id'] as String,
              childDisplayName:
                  (r['child_users'] as Map?)?['display_name'] as String?,
              parentLabel: r['parent_label'] as String?,
              pairedAt: DateTime.parse(r['paired_at'] as String),
            ))
        .toList();
  }

  /// 부모 측: 페어링 해제 (양쪽 끊김).
  Future<void> unpair(String pairingId) async {
    await SupabaseInit.client.from('pairings').delete().eq('id', pairingId);
  }
}

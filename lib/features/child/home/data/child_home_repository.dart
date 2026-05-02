import '../../../../core/supabase/supabase_init.dart';

/// 자녀 홈 화면용 부모별 오늘 요약.
class ParentSummary {
  final String pairingId;
  final String parentDeviceId;
  final String label;
  final int totalToday;
  final int takenToday;
  final int missedToday;

  ParentSummary({
    required this.pairingId,
    required this.parentDeviceId,
    required this.label,
    required this.totalToday,
    required this.takenToday,
    required this.missedToday,
  });
}

class ChildHomeRepository {
  Future<List<ParentSummary>> listParents() async {
    final uid = SupabaseInit.client.auth.currentUser?.id;
    if (uid == null) return [];

    final pairs = await SupabaseInit.client
        .from('pairings')
        .select('id, parent_device_id, parent_label')
        .eq('child_user_id', uid);

    final today = DateTime.now();
    final ymd = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final result = <ParentSummary>[];
    for (final p in (pairs as List)) {
      final pid = p['parent_device_id'] as String;
      final events = await SupabaseInit.client
          .from('dose_events')
          .select('status')
          .eq('parent_device_id', pid)
          .eq('date', ymd);
      final list = (events as List).map((e) => e['status'] as String).toList();
      result.add(ParentSummary(
        pairingId: p['id'] as String,
        parentDeviceId: pid,
        label: (p['parent_label'] as String?) ?? '부모님',
        totalToday: list.length,
        takenToday: list.where((s) => s == 'taken').length,
        missedToday: list.where((s) => s == 'missed').length,
      ));
    }
    return result;
  }
}

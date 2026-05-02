import '../../../../core/supabase/supabase_init.dart';

/// 부모 상세 화면용 단일 복용 이벤트 뷰.
class DoseEventView {
  final String medicationName;
  final String slotId;
  final DateTime occurredAt;
  final String status;

  DoseEventView({
    required this.medicationName,
    required this.slotId,
    required this.occurredAt,
    required this.status,
  });
}

class ParentDetailRepository {
  Future<List<DoseEventView>> todayEvents(String parentDeviceId) async {
    final today = DateTime.now();
    final ymd = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final rows = await SupabaseInit.client
        .from('dose_events')
        .select('slot_id, status, occurred_at, medication_id, medications(name)')
        .eq('parent_device_id', parentDeviceId)
        .eq('date', ymd)
        .order('occurred_at');

    return (rows as List)
        .map((r) => DoseEventView(
              medicationName:
                  (r['medications'] as Map?)?['name'] as String? ?? '',
              slotId: r['slot_id'] as String,
              occurredAt: DateTime.parse(r['occurred_at'] as String),
              status: r['status'] as String,
            ))
        .toList();
  }
}

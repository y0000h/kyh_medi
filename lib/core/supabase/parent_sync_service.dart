import 'package:hive/hive.dart';
import '../hive/hive_init.dart';
import '../../features/parent/intake/domain/dose_event.dart';
import '../../features/parent/medication/domain/medication.dart';
import '../../features/parent/settings/domain/app_settings.dart';
import 'supabase_init.dart';

/// 부모 → Supabase 단방향 push.
///
/// 모든 메서드는 fire-and-forget — 실패해도 부모 앱 동작에 영향 없음 (try/catch로 무시).
/// 페어링 안 된 부모(`pairedSupabaseUserId == null`)는 함수가 아예 no-op 으로 끝남.
class ParentSyncService {
  String? _userId() {
    final settings = Hive.box<AppSettings>(HiveInit.settingsBox).get('app');
    return settings?.pairedSupabaseUserId;
  }

  bool get isLinked => _userId() != null;

  /// 약 추가/수정 시 호출.
  Future<void> upsertMedication(Medication m) async {
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client.from('medications').upsert({
        'id': m.id,
        'parent_device_id': uid,
        'name': m.name,
        'updated_at': DateTime.now().toIso8601String(),
        'deleted_at': m.deletedAt?.toIso8601String(),
      });
    } catch (_) {/* fire-and-forget */}
  }

  /// 약 삭제 시 호출.
  Future<void> markMedicationDeleted(String medicationId) async {
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client
          .from('medications')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', medicationId)
          .eq('parent_device_id', uid);
    } catch (_) {}
  }

  /// 복용 / 미복용 이벤트 발생 시 호출. pending/skipped는 미러 안 함.
  ///
  /// `dose_events.id`는 Supabase에선 단순 문자열, Hive에선 `YYYY-MM-DD|slot|med` 형태이므로
  /// `|`/`:`을 `-`로 변환해서 호환되는 문자열로 보낸다. RLS는 parent_device_id 기준이라
  /// ID 형식 자체는 자유.
  Future<void> insertDoseEvent(DoseEvent e) async {
    if (e.status != DoseEvent.statusTaken && e.status != DoseEvent.statusMissed) {
      return;
    }
    final uid = _userId();
    if (uid == null) return;
    try {
      await SupabaseInit.client.from('dose_events').insert({
        'id': e.id.replaceAll('|', '-').replaceAll(':', '-'),
        'parent_device_id': uid,
        'medication_id': e.medicationId,
        'slot_id': e.slotId,
        'date': '${e.date.year.toString().padLeft(4, '0')}-'
            '${e.date.month.toString().padLeft(2, '0')}-'
            '${e.date.day.toString().padLeft(2, '0')}',
        'status': e.status,
        'occurred_at': (e.takenAt ?? DateTime.now()).toIso8601String(),
      });
    } catch (_) {}
  }
}

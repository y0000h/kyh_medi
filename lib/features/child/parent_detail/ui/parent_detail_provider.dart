import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_init.dart';
import '../data/parent_detail_repository.dart';

class ParentDetailProvider extends ChangeNotifier {
  final String parentDeviceId;
  final ParentDetailRepository _repo = ParentDetailRepository();
  RealtimeChannel? _channel;

  ParentDetailProvider(this.parentDeviceId);

  List<DoseEventView> _events = const [];
  List<DoseEventView> get events => _events;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _events = await _repo.todayEvents(parentDeviceId);
    _loading = false;
    notifyListeners();
  }

  void subscribeRealtime() {
    _channel = SupabaseInit.client.channel('parent_detail:$parentDeviceId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'dose_events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'parent_device_id',
          value: parentDeviceId,
        ),
        callback: (_) => load(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'medications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'parent_device_id',
          value: parentDeviceId,
        ),
        callback: (_) => load(),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

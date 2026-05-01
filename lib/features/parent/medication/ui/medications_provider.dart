import 'package:flutter/foundation.dart';
import '../../../../core/supabase/parent_sync_service.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationRepository _repo;
  final ParentSyncService? _sync;

  MedicationsProvider(this._repo, {ParentSyncService? sync}) : _sync = sync {
    _repo.watch().listen((_) {
      _items = _repo.findActive();
      notifyListeners();
    });
    _items = _repo.findActive();
  }

  List<Medication> _items = const [];
  List<Medication> get items => _items;

  Future<void> add(Medication m) async {
    await _repo.insert(m);
    _items = _repo.findActive();
    notifyListeners();
    _sync?.upsertMedication(m);
  }

  Future<void> remove(String id) async {
    await _repo.softDelete(id);
    _items = _repo.findActive();
    notifyListeners();
    _sync?.markMedicationDeleted(id);
  }
}

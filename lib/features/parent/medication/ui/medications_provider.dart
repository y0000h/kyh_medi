import 'package:flutter/foundation.dart';
import '../data/medication_repository.dart';
import '../domain/medication.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationRepository _repo;
  MedicationsProvider(this._repo) {
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
  }

  Future<void> remove(String id) async {
    await _repo.softDelete(id);
    _items = _repo.findActive();
    notifyListeners();
  }
}

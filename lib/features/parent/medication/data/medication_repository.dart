import 'package:hive/hive.dart';
import '../domain/medication.dart';

class MedicationRepository {
  final Box<Medication> _box;
  MedicationRepository(this._box);

  Future<void> insert(Medication m) async => _box.put(m.id, m);

  Future<void> update(Medication m) async => _box.put(m.id, m);

  List<Medication> findActive() => _box.values
      .where((m) => m.deletedAt == null)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Medication? findById(String id) => _box.get(id);

  Future<void> softDelete(String id) async {
    final m = _box.get(id);
    if (m == null) return;
    m.deletedAt = DateTime.now();
    await m.save();
  }

  Stream<BoxEvent> watch() => _box.watch();
}

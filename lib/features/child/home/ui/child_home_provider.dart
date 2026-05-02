import 'package:flutter/foundation.dart';
import '../data/child_home_repository.dart';

class ChildHomeProvider extends ChangeNotifier {
  final ChildHomeRepository _repo = ChildHomeRepository();

  List<ParentSummary> _items = const [];
  List<ParentSummary> get items => _items;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.listParents();
    _loading = false;
    notifyListeners();
  }
}

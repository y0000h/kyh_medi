import 'package:flutter/foundation.dart';
import '../data/pairing_repository.dart';

/// 자녀와 연결 화면 전용 상태. 코드 발급/만료/페어링 목록 관리.
class PairingProvider extends ChangeNotifier {
  final PairingRepository _repo = PairingRepository();

  String? _code;
  String? get code => _code;
  DateTime? _codeExpiresAt;
  DateTime? get codeExpiresAt => _codeExpiresAt;

  List<PairingInfo> _pairings = const [];
  List<PairingInfo> get pairings => _pairings;

  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> issueCode() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _code = await _repo.createCode();
      _codeExpiresAt = DateTime.now().add(const Duration(minutes: 10));
    } catch (e) {
      _error = '코드를 발급할 수 없어요: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPairings() async {
    _pairings = await _repo.listMine();
    notifyListeners();
  }

  Future<void> unpair(String pairingId) async {
    await _repo.unpair(pairingId);
    await loadPairings();
  }
}

import 'package:hive/hive.dart';
import '../domain/app_settings.dart';

class SettingsRepository {
  static const _key = 'app';
  final Box<AppSettings> _box;
  SettingsRepository(this._box);

  AppSettings get current {
    var s = _box.get(_key);
    if (s == null) {
      s = AppSettings();
      _box.put(_key, s);
    }
    return s;
  }

  Future<void> setUserMode(String mode) async {
    final s = current;
    s.userMode = mode;
    await s.save();
  }

  Future<void> setOnboardingDone(bool v) async {
    final s = current;
    s.onboardingDone = v;
    await s.save();
  }

  Future<void> setAdsRemoved(bool v) async {
    final s = current;
    s.adsRemoved = v;
    await s.save();
  }

  Future<void> setPairedSupabaseUserId(String? id) async {
    final s = current;
    s.pairedSupabaseUserId = id;
    await s.save();
  }

  Future<void> setFcmToken(String? token) async {
    final s = current;
    s.fcmToken = token;
    await s.save();
  }
}

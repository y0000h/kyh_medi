import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings extends HiveObject {
  @HiveField(0) String userMode;              // 'parent' | 'child' | '' (미선택)
  @HiveField(1) bool adsRemoved;
  @HiveField(2) double seniorFontScale;
  @HiveField(3) String? pairedSupabaseUserId; // 부모 anonymous user_id (페어링 시 저장)
  @HiveField(4) String? fcmToken;             // 자녀 FCM 토큰
  @HiveField(5) bool onboardingDone;

  AppSettings({
    this.userMode = '',
    this.adsRemoved = false,
    this.seniorFontScale = 1.0,
    this.pairedSupabaseUserId,
    this.fcmToken,
    this.onboardingDone = false,
  });

  static const modeParent = 'parent';
  static const modeChild = 'child';
}

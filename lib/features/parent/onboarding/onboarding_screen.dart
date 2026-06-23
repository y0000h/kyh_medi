// lib/features/parent/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/hive/hive_init.dart';
import '../../../core/notification/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../settings/data/settings_repository.dart';
import '../settings/domain/app_settings.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _allowPermissions() async {
    await NotificationService.requestPermissions();
    final box = Hive.box<AppSettings>(HiveInit.settingsBox);
    await SettingsRepository(box).setOnboardingDone(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.seniorBg),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // 히어로 글로우 + 알약 글리프
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180, height: 180,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Color(0x553D7BF5), Color(0x003D7BF5)],
                            ),
                          ),
                        ),
                        Container(
                          width: 100, height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.peach,
                            boxShadow: [
                              BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color(0x33000000)),
                            ],
                          ),
                          child: const Icon(Icons.medication_rounded, size: 50, color: AppColors.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text('한 알도,\n잊지 않게',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800,
                      color: AppColors.ink, height: 1.15, letterSpacing: -0.5,
                    )),
                const SizedBox(height: 16),
                const Text('어르신이 약을 잊지 않으시도록\n정해진 시간에 알림을 보내드려요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: AppColors.ink2, height: 1.5)),
                const Spacer(),
                const Text('알림 권한이 필요해요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.inkMute)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: FilledButton(
                    onPressed: _allowPermissions,
                    child: const Text('알림 받기 시작',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

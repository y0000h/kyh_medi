// lib/features/parent/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/hive/hive_init.dart';
import '../../../core/notification/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/senior_button.dart';
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
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 60),
          const Icon(Icons.medication, size: 100, color: AppColors.pillDeep),
          const SizedBox(height: 32),
          const Text('한 알도, 잊지 않게',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text('어르신이 약을 잊지 않으시도록 정해진 시간에 알림을 보내드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.ink2)),
          const Spacer(),
          const Text('알림 권한이 필요해요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.ink2)),
          const SizedBox(height: 12),
          SeniorButton(label: '알림 받기 시작', onPressed: _allowPermissions, large: true),
          const SizedBox(height: 32),
        ]),
      )),
    );
  }
}

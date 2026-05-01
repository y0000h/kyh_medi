// lib/features/mode_select/mode_select_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/hive/hive_init.dart';
import '../../core/theme/tokens.dart';
import '../parent/settings/data/settings_repository.dart';
import '../parent/settings/domain/app_settings.dart';

class ModeSelectScreen extends StatelessWidget {
  final void Function(String mode) onSelected;
  const ModeSelectScreen({super.key, required this.onSelected});

  Future<void> _select(BuildContext context, String mode) async {
    final box = Hive.box<AppSettings>(HiveInit.settingsBox);
    await SettingsRepository(box).setUserMode(mode);
    onSelected(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 80),
          const Icon(Icons.medication, size: 100, color: AppColors.pillDeep),
          const SizedBox(height: 32),
          const Text('한 알도, 잊지 않게',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('어떻게 사용하시나요?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.ink2)),
          const Spacer(),
          // 부모 큰 버튼
          SizedBox(height: 100, child: ElevatedButton(
            onPressed: () => _select(context, AppSettings.modeParent),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pillDeep, foregroundColor: Colors.white,
            ),
            child: const Text('부모님이세요?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 12),
          const Text('내가 약을 먹을 시간을 알려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
          const SizedBox(height: 32),
          // 자녀 버튼 (조금 더 작게)
          SizedBox(height: 80, child: OutlinedButton(
            onPressed: () => _select(context, AppSettings.modeChild),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pillDeep,
              side: const BorderSide(color: AppColors.pillDeep, width: 2),
            ),
            child: const Text('자녀세요?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          const Text('부모님 약 복용 상태를 확인하고 싶어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.ink2)),
          const SizedBox(height: 60),
        ]),
      )),
    );
  }
}

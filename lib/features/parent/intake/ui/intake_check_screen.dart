// lib/features/parent/intake/ui/intake_check_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/notification/notification_scheduler.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../medication/domain/medication.dart';
import 'intake_provider.dart';

class IntakeCheckScreen extends StatelessWidget {
  final TodaySlotView slotView;
  const IntakeCheckScreen({super.key, required this.slotView});

  @override
  Widget build(BuildContext context) {
    final hh = slotView.slot.hour.toString().padLeft(2, '0');
    final mm = slotView.slot.minute.toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('${slotView.slot.label} $hh:$mm',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 64,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl,
                ),
                children: [
                  for (final m in slotView.medications)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _MedCard(med: m),
                    ),
                ],
              ),
            ),
            // 큰 복용 완료 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity, height: 64,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.jade,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 26),
                  label: const Text('복용 완료',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  onPressed: () async {
                    final intake = context.read<IntakeProvider>();
                    // 오늘 dayOffset = 0 retry +10/+20 알림 cancel
                    final hash = NotificationIdEncoder.hashSlotId(slotView.slot.id);
                    await NotificationService.cancelMany(
                      NotificationIdEncoder.idsForSlotInstance(slotHash: hash, dayOffset: 0),
                    );
                    final today = DateTime.now();
                    await intake.markSlotTaken(slotView.slot.id,
                        DateTime(today.year, today.month, today.day));
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = med.photoPath != null && File(med.photoPath!).existsSync();
    final tint = AppColors.fromHex(med.colorHex);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x10000000)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          hasPhoto
              ? ClipRRect(
                  borderRadius: AppRadius.lgAll,
                  child: Image.file(File(med.photoPath!), width: 72, height: 72, fit: BoxFit.cover))
              : Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.16),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(Icons.medication_rounded, color: tint, size: 36),
                ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                if (med.dose != null && med.dose!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(med.dose!, style: const TextStyle(fontSize: 15, color: AppColors.inkMute)),
                ],
                if (med.memo != null && med.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(med.memo!, style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
                ],
              ],
            ),
          ),
          if (med.mealTimingLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.pillDeep.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillAll,
              ),
              child: Text(med.mealTimingLabel!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.pillDeep)),
            ),
        ],
      ),
    );
  }
}

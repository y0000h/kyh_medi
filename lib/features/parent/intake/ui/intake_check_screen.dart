// lib/features/parent/intake/ui/intake_check_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/notification/notification_scheduler.dart';
import '../../../../core/notification/notification_service.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import 'intake_provider.dart';

class IntakeCheckScreen extends StatelessWidget {
  final TodaySlotView slotView;
  const IntakeCheckScreen({super.key, required this.slotView});

  @override
  Widget build(BuildContext context) {
    final hh = slotView.slot.hour.toString().padLeft(2, '0');
    final mm = slotView.slot.minute.toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: Text('${slotView.slot.label} $hh:$mm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final m in slotView.medications)
            Card(margin: const EdgeInsets.only(bottom: 16),
              child: Padding(padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (m.photoPath != null)
                    ClipRRect(borderRadius: AppRadius.smAll,
                      child: Image.file(File(m.photoPath!),
                          width: 96, height: 96, fit: BoxFit.cover))
                  else
                    Container(width: 96, height: 96, color: AppColors.paper2,
                      child: const Icon(Icons.medication, size: 48, color: AppColors.pillDeep)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    if (m.memo != null)
                      Text(m.memo!, style: const TextStyle(fontSize: 16)),
                  ])),
                ])),
            ),
          const SizedBox(height: 24),
          SeniorButton(
            label: '복용 완료',
            large: true,
            variant: SeniorButtonVariant.success,
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
        ]),
      ),
    );
  }
}

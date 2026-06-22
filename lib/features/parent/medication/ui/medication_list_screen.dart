import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../monetization/ad_banner.dart';
import '../domain/medication.dart';
import 'medications_provider.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Medication m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('약을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.care),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<MedicationsProvider>().remove(m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('약 관리', style: TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 72,
      ),
      body: Column(children: [
        Expanded(child: meds.isEmpty
            ? _empty()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.x4l,
                ),
                itemCount: meds.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) => _MedCard(
                  med: meds[i],
                  onDelete: () => _confirmDelete(context, meds[i]),
                ),
              )),
        const AdBanner(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicationFormScreen())),
        label: const Text('새 약 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication_outlined, size: 48, color: AppColors.inkMute),
              const SizedBox(height: AppSpacing.md),
              const Text('아직 등록된 약이 없어요',
                  style: TextStyle(fontSize: 16, color: AppColors.ink2)),
            ],
          ),
        ),
      );
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onDelete;
  const _MedCard({required this.med, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = med.photoPath != null && File(med.photoPath!).existsSync();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x10000000)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // 알약 아바타
            hasPhoto
                ? ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: Image.file(File(med.photoPath!), width: 52, height: 52, fit: BoxFit.cover),
                  )
                : Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.pillDeep.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppColors.pillDeep, size: 26),
                  ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink,
                      )),
                  if (med.memo != null && med.memo!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(med.memo!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: AppColors.inkMute)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 24, color: AppColors.inkMute),
              tooltip: '삭제',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

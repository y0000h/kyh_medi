import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../monetization/ad_banner.dart';
import 'medications_provider.dart';
import 'medication_form_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    return Scaffold(
      appBar: AppBar(title: const Text('약 관리')),
      body: Column(children: [
        Expanded(child: meds.isEmpty
            ? const Center(child: Text('아직 등록된 약이 없어요',
                style: TextStyle(fontSize: 20)))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: meds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final m = meds[i];
                  return Card(child: ListTile(
                    leading: m.photoPath != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: Image.file(File(m.photoPath!),
                                width: 48, height: 48, fit: BoxFit.cover))
                        : const Icon(Icons.medication, size: 36, color: AppColors.pillDeep),
                    title: Text(m.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    subtitle: m.memo != null ? Text(m.memo!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 28),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('약을 삭제할까요?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context.read<MedicationsProvider>().remove(m.id);
                        }
                      },
                    ),
                  ));
                },
              )),
        const AdBanner(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicationFormScreen())),
        label: const Text('새 약 추가', style: TextStyle(fontSize: 18)),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

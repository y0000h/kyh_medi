import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import 'parent_detail_provider.dart';

class ParentDetailScreen extends StatelessWidget {
  final String parentDeviceId;
  final String label;

  const ParentDetailScreen({
    super.key,
    required this.parentDeviceId,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentDetailProvider(parentDeviceId)
        ..load()
        ..subscribeRealtime(),
      child: _Body(label: label),
    );
  }
}

class _Body extends StatelessWidget {
  final String label;
  const _Body({required this.label});

  IconData _icon(String s) => switch (s) {
        'taken' => Icons.check_circle_rounded,
        'missed' => Icons.cancel_rounded,
        _ => Icons.schedule_rounded,
      };

  Color _color(String s) => switch (s) {
        'taken' => AppColors.caregiverSuccess,
        'missed' => AppColors.caregiverDanger,
        _ => AppColors.caregiverInkMute,
      };

  String _statusLabel(String s) => switch (s) {
        'taken' => '복용 완료',
        'missed' => '미복용',
        _ => '대기 중',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentDetailProvider>();
    return Scaffold(
      backgroundColor: AppColors.caregiverBg,
      appBar: AppBar(
        title: Text('$label 의 오늘', style: const TextStyle(fontWeight: FontWeight.w800)),
        toolbarHeight: 64,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ParentDetailProvider>().load(),
        child: p.events.isEmpty && !p.loading
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x4l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medication_outlined, size: 48, color: AppColors.caregiverInkMute),
                      const SizedBox(height: AppSpacing.md),
                      const Text('오늘 아직 등록된 복용 기록이 없어요.',
                          style: TextStyle(fontSize: 15, color: AppColors.caregiverInk2)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.x4l,
                ),
                itemCount: p.events.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final e = p.events[i];
                  final c = _color(e.status);
                  final hh = e.occurredAt.toLocal().hour.toString().padLeft(2, '0');
                  final mm = e.occurredAt.toLocal().minute.toString().padLeft(2, '0');
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.caregiverCard,
                      borderRadius: AppRadius.xlAll,
                      border: Border.all(color: AppColors.caregiverBorder, width: 1),
                      boxShadow: const [
                        BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x10000000)),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                          child: Icon(_icon(e.status), color: c, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.medicationName,
                                  style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.caregiverInk)),
                              const SizedBox(height: 2),
                              Text('$hh:$mm',
                                  style: const TextStyle(fontSize: 14, color: AppColors.caregiverInkMute)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: c, borderRadius: AppRadius.pillAll),
                          child: Text(_statusLabel(e.status),
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

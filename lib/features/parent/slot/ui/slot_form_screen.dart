// lib/features/parent/slot/ui/slot_form_screen.dart
//
// 시간 슬롯 직접 등록/수정 폼 — 약 등록 마법사(medication_form_screen)와 같은
// 라이트 카드 톤. 슬롯 이름 / 시간 / 요일 / 이 시간에 드실 약을 한 화면에서 입력.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../medication/domain/medication.dart';
import '../../medication/ui/medications_provider.dart';
import '../domain/time_slot.dart';
import 'slots_provider.dart';

class SlotFormScreen extends StatefulWidget {
  /// edit 모드 — 기존 슬롯을 수정하려면 전달.
  /// 저장 시 기존 슬롯을 remove + 새 슬롯 create (slot id는 새로 발급).
  final TimeSlot? existing;
  final List<String>? existingMedicationIds;

  const SlotFormScreen({super.key, this.existing, this.existingMedicationIds});
  @override
  State<SlotFormScreen> createState() => _SlotFormScreenState();
}

class _SlotFormScreenState extends State<SlotFormScreen> {
  late final TextEditingController _label;
  late TimeOfDay _time;
  late int _daysMask;
  late final Set<String> _selectedMeds;
  bool _saving = false;

  static const _dayDefs = [
    (1, '월'), (2, '화'), (4, '수'), (8, '목'), (16, '금'), (32, '토'), (64, '일'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '아침');
    _time = e == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: e.hour, minute: e.minute);
    _daysMask = e?.daysOfWeek ?? TimeSlot.everyday;
    _selectedMeds = {...?widget.existingMedicationIds};
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약을 1개 이상 선택해주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<SlotsProvider>();
      // edit: 기존 슬롯 제거(알림 취소 포함) → 새 슬롯 생성. 같은 흐름이라 atomic은 X
      // (실패 시 둘 다 없을 수 있어 사용자에게 SnackBar로 알림). slot_medications는 로컬 only.
      if (widget.existing != null) {
        await provider.remove(widget.existing!.id);
      }
      await provider.create(
        label: _label.text.trim().isEmpty ? '시간 슬롯' : _label.text.trim(),
        hour: _time.hour,
        minute: _time.minute,
        daysOfWeek: _daysMask,
        medicationIds: _selectedMeds.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xl, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                  Text(isEdit ? '시간 슬롯 수정' : '시간 슬롯 등록',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('슬롯 이름'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _label,
                      decoration: const InputDecoration(hintText: '예: 아침'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _sectionLabel('시간'),
                    const SizedBox(height: AppSpacing.sm),
                    _timeField(),
                    const SizedBox(height: AppSpacing.xxl),
                    _sectionLabel('요일'),
                    const SizedBox(height: AppSpacing.sm),
                    _dayPicker(),
                    const SizedBox(height: AppSpacing.xxl),
                    _sectionLabel('이 시간에 드실 약'),
                    const SizedBox(height: AppSpacing.sm),
                    if (meds.isEmpty)
                      _emptyMeds()
                    else
                      ...meds.map(_medTile),
                  ],
                ),
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity, height: 58,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '저장 중…' : '저장',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink2),
      );

  Widget _timeField() {
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 22, color: AppColors.inkMute),
            const SizedBox(width: AppSpacing.md),
            Text('$hh:$mm',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.pillDeep)),
            const Spacer(),
            Text(_time.format(context),
                style: const TextStyle(fontSize: 15, color: AppColors.inkMute)),
          ],
        ),
      ),
    );
  }

  Widget _dayPicker() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _dayDefs.map((d) {
        final selected = (_daysMask & d.$1) != 0;
        return GestureDetector(
          onTap: () => setState(() =>
              _daysMask = selected ? _daysMask & ~d.$1 : _daysMask | d.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.pillDeep : AppColors.paper,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.pillDeep : AppColors.line,
                width: 1,
              ),
            ),
            child: Text(d.$2,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.onPrimary : AppColors.ink2,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _medTile(Medication m) {
    final selected = _selectedMeds.contains(m.id);
    final tint = AppColors.fromHex(m.colorHex);
    final hasPhoto = m.photoPath != null && File(m.photoPath!).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => setState(() {
          if (selected) {
            _selectedMeds.remove(m.id);
          } else {
            _selectedMeds.add(m.id);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.pillDeep : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              hasPhoto
                  ? ClipRRect(
                      borderRadius: AppRadius.pillAll,
                      child: Image.file(File(m.photoPath!), width: 44, height: 44, fit: BoxFit.cover),
                    )
                  : Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication_rounded, color: tint, size: 24),
                    ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(m.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              // 체크 표시
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: selected ? AppColors.pillDeep : Colors.transparent,
                  shape: BoxShape.circle,
                  border: selected ? null : Border.all(color: AppColors.line, width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 17, color: AppColors.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyMeds() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.paper2,
          borderRadius: AppRadius.lgAll,
        ),
        child: const Text('먼저 약을 등록해주세요',
            style: TextStyle(fontSize: 15, color: AppColors.inkMute)),
      );
}

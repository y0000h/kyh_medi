import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../../../shared/widgets/senior_input.dart';
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

  Widget _dayChip(int dayBit, String label) {
    final selected = (_daysMask & dayBit) != 0;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 16)),
      selected: selected,
      onSelected: (_) => setState(() =>
          _daysMask = selected ? _daysMask & ~dayBit : _daysMask | dayBit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationsProvider>().items;
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '시간 슬롯 수정' : '시간 슬롯 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SeniorInput(controller: _label, label: '슬롯 이름', hint: '예: 아침'),
          const SizedBox(height: 24),
          const Text('시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SeniorButton(label: _time.format(context), onPressed: _pickTime),
          const SizedBox(height: 24),
          const Text('요일', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _dayChip(1, '월'), _dayChip(2, '화'), _dayChip(4, '수'),
            _dayChip(8, '목'), _dayChip(16, '금'), _dayChip(32, '토'), _dayChip(64, '일'),
          ]),
          const SizedBox(height: 24),
          const Text('이 시간에 드실 약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (meds.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('먼저 약을 등록해주세요')),
          ...meds.map((Medication m) => CheckboxListTile(
                title: Text(m.name, style: const TextStyle(fontSize: 18)),
                value: _selectedMeds.contains(m.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedMeds.add(m.id);
                  } else {
                    _selectedMeds.remove(m.id);
                  }
                }),
              )),
          const SizedBox(height: 32),
          SeniorButton(
            label: _saving ? '저장 중…' : '저장',
            onPressed: _saving ? null : _save,
            large: true,
          ),
        ]),
      ),
    );
  }
}

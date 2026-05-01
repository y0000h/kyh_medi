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
  const SlotFormScreen({super.key});
  @override
  State<SlotFormScreen> createState() => _SlotFormScreenState();
}

class _SlotFormScreenState extends State<SlotFormScreen> {
  final _label = TextEditingController(text: '아침');
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _daysMask = TimeSlot.everyday;
  final Set<String> _selectedMeds = {};

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (_selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약을 1개 이상 선택해주세요')),
      );
      return;
    }
    await context.read<SlotsProvider>().create(
      label: _label.text.trim().isEmpty ? '시간 슬롯' : _label.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      daysOfWeek: _daysMask,
      medicationIds: _selectedMeds.toList(),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('시간 슬롯 등록')),
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
          SeniorButton(label: '저장', onPressed: _save, large: true),
        ]),
      ),
    );
  }
}

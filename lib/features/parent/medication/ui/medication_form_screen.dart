// lib/features/parent/medication/ui/medication_form_screen.dart
//
// 약 등록 3단계 마법사 (Figma 레퍼런스):
//   ① 정보 입력 — 알약 색상 / 이름 / 메모 / 복용량 / 식사시점
//   ② 복용 기간 — 시작일 / 종료일 (휠 날짜 피커)
//   ③ 복용 시간 — 알림 토글 / 복용 시각 리스트
// 완료 시 Medication 생성 + 시각마다 TimeSlot 생성(약 연결, 알림 토글 반영).
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../slot/domain/time_slot.dart';
import '../../slot/ui/slots_provider.dart';
import '../domain/medication.dart';
import 'medications_provider.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key});
  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _PillColor {
  final String hex;
  final Color color;
  const _PillColor(this.hex, this.color);
}

const _pillColors = [
  _PillColor('#EB5757', Color(0xFFEB5757)),
  _PillColor('#3D7BF5', Color(0xFF3D7BF5)),
  _PillColor('#EFA13C', Color(0xFFEFA13C)),
  _PillColor('#5DAE4E', Color(0xFF5DAE4E)),
];

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  int _step = 0;
  bool _saving = false;

  // step 0
  int _colorIdx = 1;
  final _name = TextEditingController();
  final _memo = TextEditingController();
  final _dose = TextEditingController();
  int _mealTiming = 1; // 식후 30분

  // step 1
  late DateTime _startDate;
  late DateTime _endDate;

  // step 2
  bool _alarm = true;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _name.dispose();
    _memo.dispose();
    _dose.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  void _next() {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약 이름을 입력해주세요')),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복용 시간을 1개 이상 추가해주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    final medsProvider = context.read<MedicationsProvider>();
    final slots = context.read<SlotsProvider>();
    try {
      final med = Medication(
        id: 'med-${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
        colorHex: _pillColors[_colorIdx].hex,
        dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
        mealTiming: _mealTiming,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: DateTime.now(),
      );
      await medsProvider.add(med);
      final label = Medication.mealTimingLabels[_mealTiming];
      for (final t in _times) {
        await slots.create(
          label: label,
          hour: t.hour,
          minute: t.minute,
          daysOfWeek: TimeSlot.everyday,
          medicationIds: [med.id],
          scheduleAlarm: _alarm,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['정보 입력', '복용 기간 설정', '복용 시간 설정'];
    const nextLabels = ['다음', '다음', '저장'];
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
                    onPressed: _saving ? null : _back,
                  ),
                  // 단계 인디케이터
                  Row(children: List.generate(3, (i) => Container(
                    width: i == _step ? 22 : 8, height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i == _step ? AppColors.pillDeep : AppColors.line,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: Text(titles[_step],
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: switch (_step) {
                  0 => _stepInfo(),
                  1 => _stepDuration(),
                  _ => _stepTimes(),
                },
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity, height: 58,
                child: FilledButton(
                  onPressed: _saving ? null : _next,
                  child: Text(_saving ? '저장 중…' : nextLabels[_step],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0: 정보 입력 ──
  Widget _stepInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 색상 선택
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_pillColors.length, (i) {
            final selected = i == _colorIdx;
            return GestureDetector(
              onTap: () => setState(() => _colorIdx = i),
              child: Stack(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: _pillColors[i].color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: _pillColors[i].color, width: 2) : null,
                    ),
                    child: Icon(Icons.medication_rounded, color: _pillColors[i].color, size: 30),
                  ),
                  if (selected)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(color: AppColors.jade, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 15),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _field(_name, '약 이름', '예: 오메가3'),
        const SizedBox(height: AppSpacing.lg),
        _field(_memo, '메모 (선택)', '예: 식후 30분'),
        const SizedBox(height: AppSpacing.lg),
        _field(_dose, '복용량 (선택)', '예: 1캡슐'),
        const SizedBox(height: AppSpacing.xxl),
        const Text('식사 시점', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink2)),
        const SizedBox(height: AppSpacing.sm),
        _segmented(),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink2)),
        const SizedBox(height: 6),
        TextField(controller: c, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        children: List.generate(3, (i) {
          final selected = i == _mealTiming;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mealTiming = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.paper : Colors.transparent,
                  borderRadius: AppRadius.pillAll,
                  boxShadow: selected
                      ? const [BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x14000000))]
                      : null,
                ),
                child: Text(Medication.mealTimingLabels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.pillDeep : AppColors.inkMute,
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: 복용 기간 ──
  Widget _stepDuration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summary(),
        const SizedBox(height: AppSpacing.xxl),
        const Text('시작일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: AppSpacing.sm),
        _dateField(_startDate, (d) => setState(() {
          _startDate = d;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        })),
        const SizedBox(height: AppSpacing.xl),
        const Text('종료일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: AppSpacing.sm),
        _dateField(_endDate, (d) => setState(() => _endDate = d)),
      ],
    );
  }

  Widget _dateField(DateTime value, ValueChanged<DateTime> onPick) {
    return GestureDetector(
      onTap: () => _pickDate(value, onPick),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Text(_fmt(value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ),
    );
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPick) async {
    DateTime temp = initial;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initial,
                  minimumYear: 2023,
                  maximumYear: 2030,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity, height: 54,
                child: FilledButton(
                  onPressed: () { onPick(temp); Navigator.pop(context); },
                  child: const Text('선택 완료', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: 복용 시간 ──
  Widget _stepTimes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summary(),
        const SizedBox(height: AppSpacing.lg),
        // 알림 토글
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.line, width: 1),
          ),
          child: Row(
            children: [
              const Text('알림 받기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const Spacer(),
              Switch(value: _alarm, onChanged: (v) => setState(() => _alarm = v)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(_times.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _timeRow(i),
        )),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
              if (t != null) setState(() => _times.add(t));
            },
            icon: const Icon(Icons.add),
            label: const Text('복용 시간 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _timeRow(int i) {
    final t = _times[i];
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Text('복용 시간 ${i + 1}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: t);
              if (picked != null) setState(() => _times[i] = picked);
            },
            child: Text('$hh:$mm',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.pillDeep)),
          ),
          if (_times.length > 1) ...[
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: () => setState(() => _times.removeAt(i)),
              child: const Icon(Icons.close, size: 20, color: AppColors.inkMute),
            ),
          ],
        ],
      ),
    );
  }

  // 약 요약 행 (step 1,2 공통)
  Widget _summary() {
    final c = _pillColors[_colorIdx].color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(Icons.medication_rounded, color: c, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name.text.trim().isEmpty ? '새 약' : _name.text.trim(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                if (_dose.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_dose.text.trim(),
                      style: const TextStyle(fontSize: 14, color: AppColors.inkMute)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pillDeep.withValues(alpha: 0.12),
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(Medication.mealTimingLabels[_mealTiming],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.pillDeep)),
          ),
        ],
      ),
    );
  }
}

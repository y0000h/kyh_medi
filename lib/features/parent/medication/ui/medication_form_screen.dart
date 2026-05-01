// lib/features/parent/medication/ui/medication_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/senior_button.dart';
import '../../../../shared/widgets/senior_input.dart';
import '../domain/medication.dart';
import 'medications_provider.dart';

class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({super.key});
  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _name = TextEditingController();
  final _memo = TextEditingController();
  String? _photoPath;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'photos'));
    if (!photoDir.existsSync()) photoDir.createSync(recursive: true);
    final dest = p.join(photoDir.path, 'med_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(picked.path).copy(dest);
    setState(() => _photoPath = dest);
  }

  String _newId() {
    // 단순 UUID 대체: timestamp + random
    return 'med-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약 이름을 입력해주세요'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final m = Medication(
      id: _newId(),
      name: _name.text.trim(),
      photoPath: _photoPath,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: DateTime.now(),
    );
    await context.read<MedicationsProvider>().add(m);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 약 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SeniorInput(controller: _name, label: '약 이름', hint: '예: 혈압약'),
          const SizedBox(height: 24),
          const Text('약 사진 (선택)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_photoPath != null)
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.file(File(_photoPath!), height: 200, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: SeniorButton(
              label: '카메라', onPressed: () => _pickPhoto(ImageSource.camera))),
            const SizedBox(width: 8),
            Expanded(child: SeniorButton(
              label: '갤러리', onPressed: () => _pickPhoto(ImageSource.gallery))),
          ]),
          const SizedBox(height: 24),
          SeniorInput(controller: _memo, label: '메모 (선택)', hint: '예: 식후 30분'),
          const SizedBox(height: 32),
          SeniorButton(label: '저장', onPressed: _save, large: true),
        ]),
      ),
    );
  }
}

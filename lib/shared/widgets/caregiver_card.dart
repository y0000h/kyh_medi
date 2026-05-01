// lib/shared/widgets/caregiver_card.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class CaregiverCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const CaregiverCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.caregiverCard,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

// lib/shared/widgets/senior_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SeniorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool large;

  const SeniorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: large ? AppSizes.largeButtonHeight : AppSizes.minButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.pillDeep,
          foregroundColor: Colors.white,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: large ? 26 : AppSizes.buttonFontSize,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}

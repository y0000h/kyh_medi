// lib/shared/widgets/ring_progress.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Figma 레퍼런스의 원형 진행률 링 (예: "78%").
/// 트랙(흐린 링) 위에 액센트 호(arc)를 그리고 가운데 퍼센트 텍스트.
class RingProgress extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final Color textColor;

  const RingProgress({
    super.key,
    required this.value,
    this.size = 96,
    this.stroke = 11,
    required this.color,
    required this.trackColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          stroke: stroke,
          color: color,
          trackColor: trackColor,
        ),
        child: Center(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'NanumSquare',
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.28,
              ),
              children: [
                TextSpan(text: '$pct'),
                TextSpan(
                  text: '%',
                  style: TextStyle(fontSize: size * 0.16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2; // 12시 방향
    canvas.drawArc(rect, start, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedCirclePainter({required this.color, this.strokeWidth = 1.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final radius = size.width / 2 - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashLength = 3.0;
    const gapLength = 2.5;
    final circumference = 2 * math.pi * radius;
    const segment = dashLength + gapLength;
    final count = (circumference / segment).floor();
    if (count < 1) return;
    final adjustedGap = (circumference - count * dashLength) / count;

    for (int i = 0; i < count; i++) {
      final startAngle = -math.pi / 2 +
          (2 * math.pi * i * (dashLength + adjustedGap)) / circumference;
      final sweepAngle = (2 * math.pi * dashLength) / circumference;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

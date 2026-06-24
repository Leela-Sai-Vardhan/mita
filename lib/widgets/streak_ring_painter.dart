import 'package:flutter/material.dart';

class StatsRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  StatsRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant StatsRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

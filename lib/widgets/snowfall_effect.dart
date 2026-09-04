import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gentle snowfall rendered behind the Winter Arc card.
///
/// A lightweight [CustomPainter] instead of a Lottie asset: zero asset
/// licensing concerns, tiny APK cost, and colors that natively match the
/// app's frost palette. Flakes drift down with slight horizontal sway and
/// wrap back to the top when they leave the card.
class SnowfallEffect extends StatefulWidget {
  const SnowfallEffect({
    super.key,
    this.flakeCount = 18,
    this.flakeColor = const Color(0xFF80D8FF),
    this.opacity = 0.35,
  });

  final int flakeCount;
  final Color flakeColor;
  final double opacity;

  @override
  State<SnowfallEffect> createState() => _SnowfallEffectState();
}

class _SnowfallEffectState extends State<SnowfallEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Flake> _flakes;
  final math.Random _random = math.Random(7);

  @override
  void initState() {
    super.initState();
    _flakes = List.generate(
      widget.flakeCount,
      (_) => _Flake(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 1.0 + _random.nextDouble() * 2.0,
        fallSpeed: 0.04 + _random.nextDouble() * 0.05,
        swayAmplitude: 0.005 + _random.nextDouble() * 0.02,
        swayPhase: _random.nextDouble() * math.pi * 2,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _SnowfallPainter(
          flakes: _flakes,
          progress: _controller.value,
          color: widget.flakeColor,
          opacity: widget.opacity,
        ),
      ),
    );
  }
}

class _Flake {
  final double x;
  final double y;
  final double radius;
  final double fallSpeed;
  final double swayAmplitude;
  final double swayPhase;

  const _Flake({
    required this.x,
    required this.y,
    required this.radius,
    required this.fallSpeed,
    required this.swayAmplitude,
    required this.swayPhase,
  });
}

class _SnowfallPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double progress;
  final Color color;
  final double opacity;

  const _SnowfallPainter({
    required this.flakes,
    required this.progress,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..color = color.withValues(alpha: opacity);

    for (final flake in flakes) {
      // One controller cycle == one full fall step for every flake.
      var y = (flake.y + progress * flake.fallSpeed * 10) % 1.0;
      final sway =
          math.sin(progress * math.pi * 2 + flake.swayPhase) *
              flake.swayAmplitude;
      final x = (flake.x + sway) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        flake.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnowfallPainter oldDelegate) => true;
}

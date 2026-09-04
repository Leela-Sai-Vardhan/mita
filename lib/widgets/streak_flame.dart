import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The streak flame, rendered as a looping Lottie fire instead of the
/// static 🔥 emoji. Falls back to the emoji while the animation loads so
/// the streak indicator never flashes empty.
class StreakFlame extends StatelessWidget {
  const StreakFlame({
    super.key,
    this.size = 22,
    this.frozen = false,
  });

  final double size;

  /// When true (streak frozen), no animation renders — the caller shows
  /// the freeze state instead.
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    if (frozen) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/streak_flame.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        // The source animation is 500x690 (tall flame); repeat keeps the
        // fire alive for as long as the indicator is visible.
        errorBuilder: (context, error, stackTrace) =>
            const SizedBox.shrink(),
      ),
    );
  }
}

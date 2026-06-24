import 'package:flutter/material.dart';

class ExpandingDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  const ExpandingDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor = const Color(0xFFE94560),
    this.inactiveColor = const Color(0xFF2A2A2A),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

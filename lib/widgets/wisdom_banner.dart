import 'package:flutter/material.dart';
import '../core/theme.dart';

class WisdomBanner extends StatelessWidget {
  final Color accent;
  final List<TextSpan> parts;
  final bool isPerfectDay;

  const WisdomBanner({
    super.key,
    required this.accent,
    required this.parts,
    this.isPerfectDay = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isPerfectDay
          ? _buildContent(key: const ValueKey('perfect_day'))
          : _buildContent(key: const ValueKey('wisdom')),
    );
  }

  Widget _buildContent({Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accent == AppTheme.accent
                ? accent.withValues(alpha: 0.4)
                : accent,
            width: 2,
          ),
        ),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(children: parts),
            ),
          ),
        ],
      ),
    );
  }
}

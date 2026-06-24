import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class PulsingCta extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const PulsingCta({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<PulsingCta> createState() => _PulsingCtaState();
}

class _PulsingCtaState extends State<PulsingCta>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
            shadowColor: AppTheme.accent.withValues(alpha: 0.3),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

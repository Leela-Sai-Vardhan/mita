import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final double valueSize;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.valueSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? AppTheme.accent, size: 20),
              const SizedBox(height: 4),
            ],
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: valueSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppTheme.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

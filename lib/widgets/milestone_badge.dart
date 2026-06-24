import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/streak_milestones.dart';

class MilestoneBadge extends StatelessWidget {
  final Milestone milestone;
  final bool earned;
  final double size;

  const MilestoneBadge({
    super.key,
    required this.milestone,
    this.earned = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned
            ? AppTheme.getStreakColor(milestone.days).withValues(alpha: 0.15)
            : AppTheme.surface,
        border: Border.all(
          color: earned
              ? AppTheme.getStreakColor(milestone.days).withValues(alpha: 0.5)
              : AppTheme.borderEmpty,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              milestone.emoji,
              style: TextStyle(fontSize: size * 0.4),
            ),
            if (earned)
              Text(
                milestone.days.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getStreakColor(milestone.days),
                  height: 1.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

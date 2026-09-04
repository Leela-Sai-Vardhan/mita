import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/streak_milestones.dart';
import 'streak_flame.dart';

class StreakIndicator extends StatelessWidget {
  final int streak;
  final bool isFrozen;
  final VoidCallback onTap;

  const StreakIndicator({
    super.key,
    required this.streak,
    required this.isFrozen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFrozen ? AppTheme.streakFreeze : AppTheme.getStreakColor(streak);
    final label = StreakMilestones.getStreakTitle(streak, isFrozen: isFrozen);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outer pill with emissive glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Container(
              height: 34,
              padding: const EdgeInsets.only(left: 8, right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left — fire emoji with radial glow
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                color.withValues(alpha: 0.35),
                                color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        isFrozen
                            ? const Text('⏳',
                                style: TextStyle(fontSize: 17))
                            : const StreakFlame(size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right — number badge (perfect circle)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2422),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        streak.toString(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Bottom label
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

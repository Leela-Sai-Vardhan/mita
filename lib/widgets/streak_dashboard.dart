import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/streak_milestones.dart';
import '../providers/task_provider.dart';
import 'streak_calendar.dart';
import 'milestone_badge.dart';

class StreakDashboard extends StatelessWidget {
  final TaskProvider provider;
  final VoidCallback onClose;

  const StreakDashboard({
    super.key,
    required this.provider,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final streak = provider.streak;
    final isFrozen = provider.isStreakFrozen;
    final bestStreak = provider.bestStreak;
    final milestone = StreakMilestones.getMilestoneForDays(streak);
    final nextMilestone = StreakMilestones.getNextMilestone(streak);
    final progress = StreakMilestones.getProgressToNextMilestone(streak);
    final nextDays = StreakMilestones.getDaysToNextMilestone(streak);
    final earned = provider.earnedMilestones;
    const allMilestones = StreakMilestones.milestones;

    final streakColor = isFrozen ? AppTheme.streakFreeze : AppTheme.getStreakColor(streak);
    final streakEmoji = isFrozen ? '⏳' : '🔥';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mutedText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress ring + main streak display
          _buildProgressRing(streak, progress, streakColor, streakEmoji, milestone),
          const SizedBox(height: 16),

          // Next milestone progress text
          if (nextMilestone != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '$streak/${nextMilestone.days} — ${nextDays! - streak} more days until "${nextMilestone.title}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.mutedText,
                ),
              ),
            ),

          // Best streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderEmpty),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 18, color: AppTheme.streakMilestone),
                const SizedBox(width: 10),
                Text(
                  'Best streak: $bestStreak days',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.streakMilestone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Calendar
          StreakCalendar(
            streak: streak,
            perfectDayDates: provider.streakHistory,
            daysToShow: 14,
          ),
          const SizedBox(height: 16),

          // Earned milestones
          if (earned.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Milestones earned',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider(color: AppTheme.borderEmpty, height: 1)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allMilestones.where((m) => earned.contains(m.days)).map((m) =>
                MilestoneBadge(milestone: m, earned: true, size: 38),
              ).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Close button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(int streak, double progress, Color color, String emoji, Milestone? milestone) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _ProgressRingPainter(progress: progress, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Text(
                    streak.toString(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (milestone != null) ...[
          const SizedBox(height: 8),
          Text(
            milestone.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            milestone.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top (-π/2)
      6.2832 * progress, // 2π * progress
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

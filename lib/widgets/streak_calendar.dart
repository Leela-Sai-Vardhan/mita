import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StreakCalendar extends StatelessWidget {
  final int streak;
  final List<String> perfectDayDates;
  final int daysToShow;

  const StreakCalendar({
    super.key,
    required this.streak,
    required this.perfectDayDates,
    this.daysToShow = 14,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = _dateKey(now);
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last $daysToShow days',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(daysToShow, (i) {
            final date = now.subtract(Duration(days: daysToShow - 1 - i));
            final key = _dateKey(date);
            final isToday = key == todayStr;
            final isPerfect = perfectDayDates.contains(key);

            Color dotColor;
            if (isToday) {
              dotColor = isPerfect ? AppTheme.streakGreen : AppTheme.accent.withValues(alpha: 0.5);
            } else if (isPerfect) {
              dotColor = AppTheme.streakGreen;
            } else {
              dotColor = AppTheme.borderEmpty;
            }

            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? dotColor.withValues(alpha: 0.15) : Colors.transparent,
                border: isToday ? Border.all(color: dotColor.withValues(alpha: 0.5)) : null,
              ),
              child: Center(
                child: Text(
                  dayLabels[date.weekday - 1],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isPerfect
                        ? AppTheme.streakGreen
                        : isToday
                            ? AppTheme.mutedText
                            : AppTheme.borderEmpty,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

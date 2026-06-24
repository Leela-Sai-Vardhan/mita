import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'streak_milestones.dart';

class WisdomMessage {
  final int streakMin;
  final int streakMax;

  /// Format: list of (text, isHighlight) pairs
  final List<(String, bool)> segments;

  const WisdomMessage({
    required this.streakMin,
    required this.streakMax,
    required this.segments,
  });
}

class WisdomMessages {
  static const List<WisdomMessage> _messages = [
    WisdomMessage(
      streakMin: 0,
      streakMax: 0,
      segments: [
        ('1% ', true),
        ('better every day = ', false),
        ('37x', true),
        (' better in a year.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 1,
      streakMax: 2,
      segments: [
        ('Momentum starts with ', false),
        ('day one', true),
        ('. You\'re building it.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 3,
      streakMax: 6,
      segments: [
        ('Three tasks a day. That\'s ', false),
        ('1,095', true),
        (' in a year.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 7,
      streakMax: 13,
      segments: [
        ('A week of consistency. This is how ', false),
        ('habits', true),
        (' are built.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 14,
      streakMax: 29,
      segments: [
        ('Two weeks strong. ', false),
        ('90 tasks', true),
        (' crushed. Your future self is grateful.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 30,
      streakMax: 49,
      segments: [
        ('One month', true),
        (' of perfect days. That\'s ', false),
        ('90 tasks', true),
        (' conquered.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 50,
      streakMax: 99,
      segments: [
        ('50 days', true),
        ('. You\'re in the ', false),
        ('top 1%', true),
        (' of consistency.', false),
      ],
    ),
    WisdomMessage(
      streakMin: 100,
      streakMax: 9999,
      segments: [
        ('Century streak. ', true),
        ('You\'ve redefined what\'s possible.', false),
      ],
    ),
  ];

  static (List<TextSpan>?, bool isPerfectDay) getMessage({
    required int streak,
    required int completedCount,
    required int todayTotal,
    required bool isPerfectDay,
  }) {
    final accent = AppTheme.getStreakColor(streak);

    final base = GoogleFonts.dmSans(
      fontSize: 13,
      color: const Color(0x99FFFFFF),
      height: 1.4,
    );

    final highlight = GoogleFonts.spaceGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: accent,
      height: 1.4,
    );

    if (isPerfectDay) {
      return ([
        TextSpan(
          text: 'Perfect Day \u2713',
          style: highlight,
        ),
        TextSpan(
          text: '  +1 to the streak.',
          style: base,
        ),
      ], true);
    }

    final daysToNext = StreakMilestones.getDaysToNextMilestone(streak);
    if (daysToNext != null && daysToNext <= 3 && daysToNext > 0) {
      final next = StreakMilestones.getNextMilestone(streak);
      if (next != null) {
        return ([
          TextSpan(
            text: '${next.emoji}  ',
            style: highlight.copyWith(fontSize: 11),
          ),
          TextSpan(
            text: '$daysToNext more days until ',
            style: base,
          ),
          TextSpan(
            text: 'your next milestone!',
            style: highlight,
          ),
        ], false);
      }
    }

    for (final msg in _messages) {
      if (streak >= msg.streakMin && streak <= msg.streakMax) {
        return ([
          for (final (text, isHi) in msg.segments)
            TextSpan(text: text, style: isHi ? highlight : base),
        ], false);
      }
    }

    return (_messages.first.segments.map((s) => TextSpan(text: s.$1, style: s.$2 ? highlight : base)).toList(), false);
  }
}

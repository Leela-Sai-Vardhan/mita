class Milestone {
  final int days;
  final String title;
  final String emoji;
  final String message;

  const Milestone({
    required this.days,
    required this.title,
    required this.emoji,
    required this.message,
  });
}

class StreakMilestones {
  static const List<Milestone> milestones = [
    Milestone(days: 3, title: 'Building Momentum', emoji: '🌱',
        message: 'Three in a row. Consistency is starting to compound.'),
    Milestone(days: 5, title: 'On a Roll', emoji: '🔥',
        message: "Five days strong. You're proving you can show up."),
    Milestone(days: 7, title: 'Habit Forming', emoji: '📅',
        message: 'One full week of discipline. This is how habits are born.'),
    Milestone(days: 10, title: 'Double Digits', emoji: '💪',
        message: "Double digits! You've entered the committed zone."),
    Milestone(days: 14, title: 'Fortnight of Focus', emoji: '⚡',
        message: 'Two weeks. Your brain is adapting to consistency.'),
    Milestone(days: 21, title: 'Habit Locked', emoji: '🔒',
        message: "21 days — the habit threshold. You've rewired yourself."),
    Milestone(days: 30, title: 'Unstoppable', emoji: '🚀',
        message: "One month of excellence. Most people never reach here. You're different."),
    Milestone(days: 45, title: 'Consistency Master', emoji: '👑',
        message: "45 days. This isn't a phase — it's who you are."),
    Milestone(days: 50, title: 'Half Century', emoji: '🏅',
        message: '50 days of discipline. You are in elite territory.'),
    Milestone(days: 75, title: 'Iron Will', emoji: '⛓️',
        message: '75 days. Motivation is gone. Discipline remains.'),
    Milestone(days: 100, title: 'Century Club', emoji: '💯',
        message: 'ONE HUNDRED DAYS. Absolutely legendary.'),
    Milestone(days: 150, title: 'Platinum', emoji: '💎',
        message: "150 days. You've redefined what's possible."),
    Milestone(days: 200, title: 'Diamond', emoji: '💎',
        message: '200 days of relentless consistency.'),
    Milestone(days: 365, title: 'Year of Excellence', emoji: '🌟',
        message: 'ONE FULL YEAR. You are the 1% of the 1%.'),
    Milestone(days: 500, title: 'Immortal', emoji: '🏆',
        message: '500 days. You are in a league of your own.'),
    Milestone(days: 1000, title: 'Legendary', emoji: '🌌',
        message: "1000 days. Almost 3 years of unwavering focus. Unprecedented."),
  ];

  static Milestone? getMilestoneForDays(int days) {
    Milestone? best;
    for (final m in milestones) {
      if (days >= m.days) {
        best = m;
      } else {
        break;
      }
    }
    return best;
  }

  static Milestone? getNextMilestone(int days) {
    for (final m in milestones) {
      if (m.days > days) return m;
    }
    return null;
  }

  static int? getDaysToNextMilestone(int days) {
    final next = getNextMilestone(days);
    return next?.days;
  }

  static double getProgressToNextMilestone(int days) {
    final next = getNextMilestone(days);
    if (next == null) return 1.0;
    final prev = getMilestoneForDays(days);
    final prevDays = prev?.days ?? 0;
    final range = next.days - prevDays;
    if (range <= 0) return 1.0;
    return ((days - prevDays) / range).clamp(0.0, 1.0);
  }

  static String getStreakTitle(int days, {bool isFrozen = false}) {
    if (isFrozen) return 'At Risk';
    final m = getMilestoneForDays(days);
    return m?.title ?? 'Current Streak';
  }

  static String getStreakMessage(int days, {bool isFrozen = false}) {
    if (isFrozen) return 'Complete all 3 tasks today or your streak resets!';
    final m = getMilestoneForDays(days);
    return m?.message ?? 'Stay consistent — every perfect day counts.';
  }

  static bool isMilestoneDay(int days) {
    return milestones.any((m) => m.days == days);
  }

  static Milestone? getExactMilestone(int days) {
    for (final m in milestones) {
      if (m.days == days) return m;
    }
    return null;
  }

  static List<Milestone> getEarnedMilestones(Set<int> earnedDays) {
    return milestones.where((m) => earnedDays.contains(m.days)).toList();
  }
}

/// Pure Snapchat-style streak-freeze rules, extracted so they can be
/// unit-tested and so [TaskProvider] stays thin.
///
/// Core principle: a day only counts as missed once it has fully ended
/// (23:59 passed) without a perfect day. Opening the app mid-day never
/// consumes the weekly freeze — the user can still finish their three
/// tasks today.
///
/// Rules:
/// - Perfect today (lastPerfectDay == today) -> no action.
/// - lastPerfectDay is yesterday or later -> no action (nothing missed).
/// - lastPerfectDay is older than yesterday -> at least one full day was
///   missed. Judge by the week of the most recent missed day (yesterday):
///   - No freeze spent yet -> spend the weekly freeze, preserve the streak.
///   - Freeze spent on an earlier week -> the streak resets.
///   - Freeze spent on this same missed week -> already frozen; no change.
class StreakFreezeRules {
  StreakFreezeRules._();

  /// Monotonic week index (days since epoch / 7). Unlike calendar week
  /// numbers this never regresses across a year boundary (e.g. week 52 ->
  /// week 1), so week comparisons stay correct through New Year.
  static int weekIndex(DateTime date) {
    final days =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    return days ~/ 7;
  }

  /// What the freeze check should do for the current state.
  static StreakFreezeAction decide({
    required DateTime? lastPerfectDay,
    required DateTime now,
    required int? frozenWeek,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Perfect as recently as yesterday (or today): nothing missed.
    if (lastPerfectDay != null &&
        _dateKey(lastPerfectDay).compareTo(_dateKey(yesterday)) >= 0) {
      return StreakFreezeAction.none;
    }

    // lastPerfectDay is older than yesterday (or absent): at least one
    // full day was missed. Judge by the week of the most recent missed
    // day.
    final missedWeek = weekIndex(yesterday);

    if (frozenWeek == null) {
      return StreakFreezeAction.freeze;
    }
    if (missedWeek > frozenWeek) {
      return StreakFreezeAction.reset;
    }
    return StreakFreezeAction.alreadyFrozen;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

enum StreakFreezeAction {
  /// Nothing to do — no missed days yet.
  none,

  /// First missed week: spend the weekly freeze, preserve the streak.
  freeze,

  /// Freeze already spent on an earlier missed week: reset the streak.
  reset,

  /// Already frozen in this missed week: no state change.
  alreadyFrozen,
}

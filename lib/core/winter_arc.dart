import '../services/remote_config_service.dart';

/// The Winter Arc campaign engine.
///
/// The Winter Arc is the app's seasonal "lock in" campaign: instead of
/// waiting for January to start fresh, users commit to their three daily
/// tasks from September through the end of February and build momentum
/// through the coldest, easiest-to-skip months of the year.
///
/// All windows derive from the same start/end months (remote-configurable
/// via `seasonal.winter_arc`, defaulting to Sep 1 - Feb 28/29) so the arc,
/// the Mitzy art, and the season switch stay in sync.
class WinterArc {
  WinterArc._();

  /// First month of the arc (September).
  static const int defaultStartMonth = 9;

  /// Last month of the arc (February).
  static const int defaultEndMonth = 2;

  /// Remote-configured start month, or the default.
  static int get startMonth =>
      RemoteConfigService.instance.winterStartMonth ?? defaultStartMonth;

  /// Remote-configured end month, or the default.
  static int get endMonth =>
      RemoteConfigService.instance.winterEndMonth ?? defaultEndMonth;

  /// Whether the arc layer (art + campaign card) is enabled at all.
  static bool get enabled => RemoteConfigService.instance.winterArcEnabled;

  /// Whether [date] falls inside the Winter Arc window.
  ///
  /// Supports both normal (e.g. Mar-Aug off-season) and year-wrapping
  /// windows (Sep-Feb): when start > end the window crosses New Year.
  static bool isArcSeason(DateTime date) {
    final start = startMonth;
    final end = endMonth;
    if (start <= end) {
      return date.month >= start && date.month <= end;
    }
    return date.month >= start || date.month <= end;
  }

  /// The date the arc starts for the season [date] falls in.
  ///
  /// For a Sep-Feb arc, a date in, say, November belongs to the arc that
  /// started Sep 1 of the same year; a date in January belongs to the arc
  /// that started Sep 1 of the *previous* year.
  static DateTime arcStartFor(DateTime date) {
    final start = DateTime(date.year, startMonth, 1);
    if (date.isBefore(start)) {
      return DateTime(date.year - 1, startMonth, 1);
    }
    return start;
  }

  /// The date the arc ends (inclusive) for the season [date] falls in.
  static DateTime arcEndFor(DateTime date) {
    final startsThisYear = DateTime(date.year, startMonth, 1);
    if (date.isBefore(startsThisYear)) {
      // E.g. January: arc started last year Sep, ends this year Feb.
      final feb = DateTime(date.year, endMonth + 1, 1);
      return feb.subtract(const Duration(days: 1));
    }
    // Arc started this year; ends Feb of next year.
    final feb = DateTime(date.year + 1, endMonth + 1, 1);
    return feb.subtract(const Duration(days: 1));
  }

  /// Total days in the arc containing [date] (Sep 1 - Feb 28/29).
  static int totalDays(DateTime date) =>
      arcEndFor(date).difference(arcStartFor(date)).inDays + 1;

  /// 1-based day of the arc for [date]; 1 on opening day.
  static int dayOfArc(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .difference(arcStartFor(date))
          .inDays + 1;

  /// Days remaining in the arc after [date] (0 on the final day).
  static int daysRemaining(DateTime date) =>
      arcEndFor(date)
          .difference(DateTime(date.year, date.month, date.day))
          .inDays;

  /// Progress through the arc, 0.0 - 1.0.
  static double progress(DateTime date) =>
      (dayOfArc(date) / totalDays(date)).clamp(0.0, 1.0);

  /// The campaign phase for [date], used for copy and styling.
  ///
  /// - Lock In (first third): momentum is everything; just start.
  /// - Deep Winter (middle third): the grind; hardest days, biggest gains.
  /// - Final Stretch (last third): finish strong, arrive in spring ahead.
  static WinterArcPhase phase(DateTime date) {
    final p = progress(date);
    if (p < 1 / 3) return WinterArcPhase.lockIn;
    if (p < 2 / 3) return WinterArcPhase.deepWinter;
    return WinterArcPhase.finalStretch;
  }

  /// How many "locked in" days (perfect days, `yyyy-MM-dd` keys) fall
  /// inside the arc window containing [date].
  static int lockedInDays(List<String> streakHistory, DateTime date) {
    final start = arcStartFor(date);
    final end = arcEndFor(date);
    var count = 0;
    for (final key in streakHistory) {
      final d = DateTime.tryParse(key);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(start) && !day.isAfter(end)) count++;
    }
    return count;
  }

  /// The next round-number "locked in" milestone to chase, if any.
  static int? nextLockInMilestone(int lockedIn) {
    const steps = [7, 21, 50, 100, 150, 200];
    for (final s in steps) {
      if (lockedIn < s) return s;
    }
    return null;
  }

  /// Rotating daily motivation, stable within a day, remote-overridable.
  static String dailyMessage(DateTime date) {
    final remote = RemoteConfigService.instance.winterArcDailyMessage;
    if (remote != null && remote.isNotEmpty) return remote;
    final pool = _messagesFor(phase(date));
    // Day-of-arc indexing keeps the line stable all day, rotating daily.
    final day = dayOfArc(date);
    return pool[(day - 1 + pool.length) % pool.length];
  }

  static List<String> _messagesFor(WinterArcPhase phase) {
    switch (phase) {
      case WinterArcPhase.lockIn:
        return const [
          'Day one energy. Lock in — future you is watching.',
          'No zero days. Three tasks is all it takes.',
          'Everyone else waits for January. You started now.',
          'Small hinges swing big doors. Start with one task.',
          'The arc starts the moment you decide it does.',
          'Discipline now, momentum forever.',
        ];
      case WinterArcPhase.deepWinter:
        return const [
          'Deep winter. This is where the gains are made.',
          'Cold outside. Fire within. Keep going.',
          'The hardest days build the strongest habits.',
          'You don\'t need motivation. You need three tasks.',
          'Hibernation is for bears. You\'re built different.',
          'Every perfect day is a brick in the fortress.',
        ];
      case WinterArcPhase.finalStretch:
        return const [
          'Final stretch. Finish the arc strong.',
          'You\'ve come too far to fold now. Lock in.',
          'Spring is coming. Arrive ahead of everyone.',
          'Last stretch — make these days count.',
          'The ones who started in September finish in February.',
          'End the arc as the person who started it: locked in.',
        ];
    }
  }

  /// Short label for [phase] used in the UI.
  static String phaseLabel(WinterArcPhase phase) {
    switch (phase) {
      case WinterArcPhase.lockIn:
        return 'Lock In';
      case WinterArcPhase.deepWinter:
        return 'Deep Winter';
      case WinterArcPhase.finalStretch:
        return 'Final Stretch';
    }
  }
}

/// Campaign phases across the arc window.
enum WinterArcPhase { lockIn, deepWinter, finalStretch }

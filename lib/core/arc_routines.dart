import 'package:shared_preferences/shared_preferences.dart';
import '../services/remote_config_service.dart';

/// A single Winter Arc routine: a binary, day-end answerable habit from
/// the trend's non-negotiable canon (train, 10k steps, protein, read 10
/// pages...), tagged with a goal key and a time bucket.
class ArcRoutine {
  /// Short, binary action title, e.g. 'Train (gym or home)'.
  final String title;

  /// Goal key for grouping (health/fitness/mindfulness/learning/career/
  /// creativity/relationships).
  final String goal;

  /// Time bucket: morning / midday / evening / any.
  final String bucket;

  const ArcRoutine({
    required this.title,
    required this.goal,
    required this.bucket,
  });

  factory ArcRoutine.fromJson(Map<String, dynamic> json) => ArcRoutine(
        title: json['title'] as String? ?? '',
        goal: json['goal'] as String? ?? 'health',
        bucket: json['bucket'] as String? ?? 'any',
      );

  Map<String, dynamic> toJson() => {'title': title, 'goal': goal, 'bucket': bucket};
}

/// The Winter Arc routine system.
///
/// Research synthesis (TikTok Winter Arc / Great Lock-In + habit-app
/// patterns): the trend's core is a personal contract of 3-5 binary
/// non-negotiables ("did I do it? yes/no at day's end"). Apps that cap
/// habits at 3, frame misses without shame ("never miss twice"), and
/// recommend by time-of-day bucket retain users; goal overload burns
/// people out by week 2-3.
///
/// Provides: a curated routine catalog (remotely overridable via
/// `seasonal.winter_arc.routines`), the user's per-season contract of up
/// to 3 non-negotiables, today's adherence, and time-bucketed suggestions.
class ArcRoutines {
  ArcRoutines._();

  static const int maxContractSize = 3;
  static const String _contractKeyPrefix = 'arc_contract_';

  /// Current time bucket label (mirrors QuickPicks buckets).
  static String currentBucket(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'midday';
    if (hour >= 17 && hour < 22) return 'evening';
    return 'any';
  }

  /// The full routine catalog. Remote override first (served from
  /// mita-config.json so the catalog can be tuned without a release),
  /// curated defaults otherwise (the habits that dominate the Winter Arc
  /// trend, made binary).
  static List<ArcRoutine> catalog() {
    final remote = RemoteConfigService.instance.arcRoutines
        .map(ArcRoutine.fromJson)
        .where((r) => r.title.isNotEmpty)
        .toList();
    if (remote.isNotEmpty) return remote;
    return defaultCatalog;
  }

  /// Curated from trend research: the most-cited non-negotiables across
  /// fitness / nutrition / mind / lifestyle, each phrased so a day can
  /// end in a yes/no answer.
  static const List<ArcRoutine> defaultCatalog = [
    // Fitness
    ArcRoutine(title: 'Train (gym or home)', goal: 'fitness', bucket: 'any'),
    ArcRoutine(title: '10k steps', goal: 'fitness', bucket: 'any'),
    ArcRoutine(title: 'Run or outdoor workout', goal: 'fitness', bucket: 'morning'),
    ArcRoutine(title: 'Stretch or mobility 10 min', goal: 'health', bucket: 'morning'),
    // Nutrition
    ArcRoutine(title: 'Hit protein goal', goal: 'health', bucket: 'any'),
    ArcRoutine(title: 'No junk food today', goal: 'health', bucket: 'any'),
    ArcRoutine(title: '3L water', goal: 'health', bucket: 'any'),
    ArcRoutine(title: 'No alcohol today', goal: 'health', bucket: 'any'),
    // Mind
    ArcRoutine(title: 'Read 10 pages', goal: 'learning', bucket: 'evening'),
    ArcRoutine(title: 'Journal 5 minutes', goal: 'mindfulness', bucket: 'evening'),
    ArcRoutine(title: 'Meditate 10 minutes', goal: 'mindfulness', bucket: 'morning'),
    ArcRoutine(title: 'Deep work block (1h distraction-free)', goal: 'career', bucket: 'midday'),
    ArcRoutine(title: 'Practice a skill 30 min', goal: 'learning', bucket: 'midday'),
    ArcRoutine(title: 'No doom-scrolling', goal: 'mindfulness', bucket: 'any'),
    // Lifestyle
    ArcRoutine(title: 'Sleep 7-8 hours', goal: 'health', bucket: 'evening'),
    ArcRoutine(title: 'Wake up before 7', goal: 'career', bucket: 'morning'),
    ArcRoutine(title: 'Cold shower', goal: 'fitness', bucket: 'morning'),
    ArcRoutine(title: 'Tidy space 10 min', goal: 'creativity', bucket: 'evening'),
    ArcRoutine(title: 'Reach out to a friend', goal: 'relationships', bucket: 'evening'),
    ArcRoutine(title: 'Plan tomorrow tonight', goal: 'career', bucket: 'evening'),
  ];

  // ---- Contract -------------------------------------------------------

  /// Pref key for the contract of the arc season containing [now]
  /// (so each September starts a fresh contract).
  static String _contractKey(DateTime now) {
    // Arcs start in September; before Sep the season key is the prior year.
    final seasonStart = now.month >= 9 ? now.year : now.year - 1;
    return '$_contractKeyPrefix$seasonStart';
  }

  /// The user's saved non-negotiables for this arc season, or null when
  /// no contract has been made yet.
  static Future<List<ArcRoutine>?> loadContract(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_contractKey(now));
    if (raw == null || raw.isEmpty) return null;
    final routines = <ArcRoutine>[];
    for (final title in raw) {
      final match = catalog().where((r) => r.title == title).firstOrNull;
      if (match != null) routines.add(match);
    }
    if (routines.isEmpty) return null;
    return routines;
  }

  /// Saves the season's contract (capped at [maxContractSize]).
  static Future<void> saveContract(List<ArcRoutine> routines, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final titles = routines.take(maxContractSize).map((r) => r.title).toList();
    await prefs.setStringList(_contractKey(now), titles);
  }

  /// Today's contract state: which non-negotiables are satisfied by
  /// [todayTaskTitles] (the titles of today's *completed* tasks).
  ///
  /// A non-negotiable counts as done when today's completed tasks include
  /// its title (contracts materialize as real daily tasks, so completing
  /// the task completes the routine — one source of truth, and it feeds
  /// the streak).
  static ArcContractToday contractToday(
    List<ArcRoutine>? contract,
    List<String> todayCompletedTitles,
  ) {
    if (contract == null || contract.isEmpty) {
      return const ArcContractToday(routines: [], doneTitles: []);
    }
    final normalized = todayCompletedTitles.map(_normalize).toSet();
    final done = contract
        .where((r) => normalized.contains(_normalize(r.title)))
        .map((r) => r.title)
        .toList();
    return ArcContractToday(routines: contract, doneTitles: done);
  }

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // ---- Suggestions ----------------------------------------------------

  /// Suggests up to [count] catalog routines that aren't in the contract
  /// and aren't already on today's list, ranked by: current time bucket
  /// first, then goal alignment with [goalKeys] (the user's QuickPicks
  /// goals), then catalog order (curated popularity).
  static List<ArcRoutine> suggestions({
    required List<ArcRoutine>? contract,
    required List<String> todayTitles,
    required List<String> goalKeys,
    DateTime? now,
    int count = 3,
  }) {
    final n = now ?? DateTime.now();
    final bucket = currentBucket(n);
    final onList = todayTitles.map(_normalize).toSet();
    final inContract =
        (contract ?? const []).map((r) => _normalize(r.title)).toSet();
    final goals = goalKeys.toSet();

    final pool = catalog()
        .where((r) => !onList.contains(_normalize(r.title)))
        .where((r) => !inContract.contains(_normalize(r.title)))
        .toList();

    int score(ArcRoutine r) {
      var s = 0;
      if (r.bucket == bucket) s += 2;
      if (r.bucket == 'any') s += 1;
      if (goals.contains(r.goal)) s += 2;
      return s;
    }

    pool.sort((a, b) {
      final d = score(b) - score(a);
      if (d != 0) return d;
      return catalog().indexOf(a) - catalog().indexOf(b);
    });

    return pool.take(count).toList();
  }

  /// Whether the contract for the season containing [now] was already
  /// confirmed (so onboarding prompts once per season, not per launch).
  static Future<bool> hasConfirmedContract(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_contractKey(now)) != null;
  }
}

/// Today's contract adherence snapshot.
class ArcContractToday {
  final List<ArcRoutine> routines;
  final List<String> doneTitles;

  const ArcContractToday({required this.routines, required this.doneTitles});

  int get doneCount => doneTitles.length;

  int get totalCount => routines.length;

  bool get allDone => totalCount > 0 && doneCount == totalCount;

  bool isDone(ArcRoutine r) => doneTitles.contains(r.title);
}

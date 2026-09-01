import 'package:shared_preferences/shared_preferences.dart';
import 'goals.dart';

class QuickPicks {
  static const String prefUserGoals = 'user_goals';
  static const String prefGoalSelectionDone = 'goal_selection_done';

  static const List<String> generalPool = [
    'Drink water',
    '20 min walk',
    'Read 5 pages',
    'Journal one line',
    'Stretch 5 min',
    'Plan tomorrow\u2019s top 3',
  ];

  static Future<void> saveGoals(List<String> goalKeys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefUserGoals, goalKeys);
  }

  static Future<List<String>> getGoalKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(prefUserGoals) ?? [];
  }

  static Future<bool> isGoalSelectionDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefGoalSelectionDone) ?? false;
  }

  static Future<void> markGoalSelectionDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefGoalSelectionDone, true);
  }

  static String timeBucket() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'midday';
    return 'evening';
  }

  static String timeBucketLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  /// Returns up to [count] suggestions, prioritizing:
  /// 1. the user's own recurring history, then
  /// 2. curated pools matching their selected goals (time-aware), then
  /// 3. a general pool.
  static List<String> suggest({
    required List<String> todayTitles,
    required List<String> pastTitles,
    required List<String> goalKeys,
    int count = 3,
  }) {
    final suggestions = <String>[];

    final todayLower = todayTitles.map((t) => t.trim().toLowerCase()).toSet();

    void add(String title) {
      final norm = title.trim();
      if (norm.isEmpty) return;
      if (todayLower.contains(norm.toLowerCase())) return;
      if (suggestions.any((s) => s.toLowerCase() == norm.toLowerCase())) return;
      suggestions.add(norm);
    }

    final freq = <String, int>{};
    for (final t in pastTitles) {
      final k = t.trim().toLowerCase();
      if (k.isEmpty) continue;
      freq[k] = (freq[k] ?? 0) + 1;
    }
    final ranked = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in ranked) {
      if (suggestions.length >= count) break;
      final original = pastTitles.firstWhere(
        (t) => t.trim().toLowerCase() == e.key,
        orElse: () => e.key,
      );
      add(original);
    }
    if (suggestions.length >= count) return suggestions;

    final shift = switch (timeBucket()) {
      'morning' => 0,
      'midday' => 2,
      _ => 4,
    };

    final goalGoals = <Goal>[];
    for (final key in goalKeys) {
      final g = Goals.getByKey(key);
      if (g != null) goalGoals.add(g);
    }

    final pool = <String>[];
    for (final g in goalGoals) {
      pool.addAll(g.tasks);
    }
    if (pool.isEmpty) {
      pool.addAll(generalPool);
    }

    for (int k = 0; k < pool.length && suggestions.length < count; k++) {
      add(pool[(shift + k) % pool.length]);
    }

    return suggestions;
  }
}
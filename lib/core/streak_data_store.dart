import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized access to streak state.
///
/// TaskProvider persists the entire streak state as a single atomic JSON blob
/// under the key `streak_state`. Consumers that need to *read* streak data
/// (stats screen, backup export, JSON mirror) MUST go through this class so
/// they always see the same values as TaskProvider. It falls back to the
/// legacy individual keys only when the atomic blob is absent (older builds).
///
/// Key contract:
///   - TaskProvider WRITES via [StreakStateWriter] (the blob in `streak_state`).
///   - Everything else READS via this store, never touching legacy keys
///     unless there is no blob yet.
class StreakDataStore {
  StreakDataStore._();

  static const String stateKey = 'streak_state';

  /// Loads the streak snapshot from SharedPreferences.
  ///
  /// Returns the authoritative values from the atomic blob if present,
  /// otherwise migrates from the legacy individual keys.
  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(stateKey);

    if (stateJson != null) {
      try {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        return _normalize(state);
      } catch (_) {
        // Corrupt blob -> fall through to legacy keys.
      }
    }
    return _normalize({
      'streak': prefs.getInt('streak') ?? 0,
      'bestStreak': prefs.getInt('bestStreak') ?? 0,
      'lastPerfectDay': prefs.getString('lastPerfectDay'),
      'isStreakFrozen': prefs.getBool('isStreakFrozen') ?? false,
      'streakFrozenWeek': prefs.getInt('streakFrozenWeek'),
      'earnedMilestones': _parseLegacyMilestones(prefs),
      'streakHistory': _parseLegacyHistory(prefs),
    });
  }

  /// Convenience getters returning typed defaults.
  static Future<int> streak() async => (await load())['streak'] as int? ?? 0;
  static Future<int> bestStreak() async =>
      (await load())['bestStreak'] as int? ?? 0;
  static Future<String?> lastPerfectDay() async =>
      (await load())['lastPerfectDay'] as String?;
  static Future<bool> isFrozen() async =>
      (await load())['isStreakFrozen'] as bool? ?? false;
  static Future<int?> frozenWeek() async =>
      (await load())['streakFrozenWeek'] as int?;
  static Future<String?> earnedMilestonesJson() async {
    final list = (await load())['earnedMilestones'] as List? ?? const [];
    return jsonEncode(list);
  }

  static Future<String?> streakHistoryJson() async {
    final list = (await load())['streakHistory'] as List? ?? const [];
    return jsonEncode(list);
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> state) => {
        'streak': state['streak'] ?? 0,
        'bestStreak': state['bestStreak'] ?? 0,
        'lastPerfectDay': state['lastPerfectDay'],
        'isStreakFrozen': state['isStreakFrozen'] ?? false,
        'streakFrozenWeek': state['streakFrozenWeek'],
        'earnedMilestones': state['earnedMilestones'] ?? const <dynamic>[],
        'streakHistory': state['streakHistory'] ?? const <dynamic>[],
      };

  static List<dynamic> _parseLegacyMilestones(SharedPreferences prefs) {
    final raw = prefs.getString('earnedMilestones');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<dynamic>();
    } catch (_) {
      return const [];
    }
  }

  static List<dynamic> _parseLegacyHistory(SharedPreferences prefs) {
    final raw = prefs.getString('streakHistory');
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).cast<dynamic>();
    } catch (_) {
      return const [];
    }
  }
}

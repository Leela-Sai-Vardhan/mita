import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../data/models/task_model.dart';
import '../data/models/focus_session_model.dart';

class StatsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  int totalFocusSessions = 0;
  int completedFocusSessions = 0;
  int totalFocusSeconds = 0;
  double avgDurationSec = 0.0;
  Map<DateTime, int> focusTimeByDay = {};
  Map<DateTime, int> sessionCountByDay = {};
  Map<DateTime, int> focusTimeByWeek = {};
  DateTime? bestFocusDay;
  int bestFocusDaySeconds = 0;
  int deepFocusSessions = 0;
  int quickFocusSessions = 0;
  int totalInterruptions = 0;
  double avgInterruptions = 0.0;
  int focusStreak = 0;

  int totalTasksCreated = 0;
  int totalTasksCompleted = 0;
  int perfectDaysCount = 0;
  int bestDayTasks = 0;
  double averageTasksPerDay = 0.0;
  double weeklyCompletionRate = 0.0;
  double monthlyCompletionRate = 0.0;
  double avgTimeToCompleteSec = 0.0;
  Map<String, int> timeOfDayBreakdown = {
    'morning': 0,
    'afternoon': 0,
    'evening': 0,
  };
  List<Map<String, dynamic>> weeklyCompletionData = [];

  int streak = 0;
  int bestStreak = 0;
  List<String> streakHistory = [];
  DateTime? lastPerfectDay;

  bool isLoading = false;

  Future<void> loadStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final focusStats = await _db.getFocusSessionStats();
      totalFocusSessions = focusStats.totalSessions;
      completedFocusSessions = focusStats.completedSessions;
      totalFocusSeconds = focusStats.totalFocusSec;
      avgDurationSec = focusStats.avgDurationSec;

      focusTimeByDay = await _db.getFocusTimeByDay(7);
      sessionCountByDay = await _db.getSessionCountByDay(7);
      focusTimeByWeek = await _db.getFocusTimeByWeek(4);

      final allSessions = await _db.getFocusSessions();
      _computeDeepQuick(allSessions);
      _computeBestFocusDay(allSessions);
      _computeInterruptions(allSessions);
      _computeFocusStreak(allSessions);

      final allTasks = await _db.getAllTasks();
      _computeTaskStats(allTasks);

      await _loadStreakPrefs();
    } catch (e) {
      debugPrint('[StatsProvider] loadStats error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _computeDeepQuick(List<FocusSession> sessions) {
    deepFocusSessions = 0;
    quickFocusSessions = 0;
    for (final s in sessions) {
      if (!s.completed) continue;
      if (s.elapsedSec > 1200) {
        deepFocusSessions++;
      } else if (s.elapsedSec > 0) {
        quickFocusSessions++;
      }
    }
  }

  void _computeBestFocusDay(List<FocusSession> sessions) {
    final Map<DateTime, int> dayTotals = {};
    for (final s in sessions) {
      if (!s.completed) continue;
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      dayTotals.update(day, (v) => v + s.elapsedSec, ifAbsent: () => s.elapsedSec);
    }
    DateTime? bestDay;
    int bestSec = 0;
    for (final entry in dayTotals.entries) {
      if (entry.value > bestSec) {
        bestSec = entry.value;
        bestDay = entry.key;
      }
    }
    bestFocusDay = bestDay;
    bestFocusDaySeconds = bestSec;
  }

  void _computeInterruptions(List<FocusSession> sessions) {
    totalInterruptions = 0;
    int sessionCount = 0;
    for (final s in sessions) {
      if (!s.completed) continue;
      totalInterruptions += s.interruptions;
      sessionCount++;
    }
    avgInterruptions = sessionCount > 0 ? totalInterruptions / sessionCount : 0.0;
  }

  void _computeFocusStreak(List<FocusSession> sessions) {
    final Set<DateTime> focusDays = {};
    for (final s in sessions) {
      if (!s.completed) continue;
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      focusDays.add(day);
    }
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      if (focusDays.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    focusStreak = streak;
  }

  void _computeAvgTimeToComplete(List<Task> tasks) {
    final completed = tasks.where((t) => t.isCompleted && t.completedAt != null);
    int totalSec = 0;
    int count = 0;
    for (final task in completed) {
      final diff = task.completedAt!.difference(task.date);
      if (diff.inSeconds > 0) {
        totalSec += diff.inSeconds;
        count++;
      }
    }
    avgTimeToCompleteSec = count > 0 ? totalSec / count : 0.0;
  }

  void _computeTaskStats(List<Task> allTasks) {
    totalTasksCreated = allTasks.length;
    totalTasksCompleted = allTasks.where((t) => t.isCompleted).length;

    final Map<DateTime, List<Task>> grouped = {};
    for (final task in allTasks) {
      final key = DateTime(task.date.year, task.date.month, task.date.day);
      grouped.putIfAbsent(key, () => []).add(task);
    }

    perfectDaysCount = 0;
    bestDayTasks = 0;
    for (final entry in grouped.entries) {
      final tasks = entry.value;
      if (tasks.length >= 3 && tasks.every((t) => t.isCompleted)) {
        perfectDaysCount++;
      }
      if (tasks.length > bestDayTasks) {
        bestDayTasks = tasks.length;
      }
    }

    if (allTasks.isNotEmpty) {
      final firstDate = allTasks.last.date;
      final daysSince = DateTime.now().difference(firstDate).inDays + 1;
      averageTasksPerDay = daysSince > 0 ? allTasks.length / daysSince : 0.0;
    } else {
      averageTasksPerDay = 0.0;
    }

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTasks = allTasks.where((t) => t.date.isAfter(weekAgo)).toList();
    weeklyCompletionRate =
        weekTasks.isEmpty ? 0.0 : weekTasks.where((t) => t.isCompleted).length / weekTasks.length;

    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    final monthTasks = allTasks.where((t) => t.date.isAfter(monthAgo)).toList();
    monthlyCompletionRate =
        monthTasks.isEmpty ? 0.0 : monthTasks.where((t) => t.isCompleted).length / monthTasks.length;

    timeOfDayBreakdown = _computeTimeOfDay(allTasks);
    weeklyCompletionData = _computeWeeklyCompletion(allTasks);
    _computeAvgTimeToComplete(allTasks);
  }

  Map<String, int> _computeTimeOfDay(List<Task> tasks) {
    int morning = 0, afternoon = 0, evening = 0;
    final completed = tasks.where((t) => t.isCompleted && t.completedAt != null);
    for (final task in completed) {
      final hour = task.completedAt!.hour;
      if (hour >= 5 && hour < 12) {
        morning++;
      } else if (hour >= 12 && hour < 17) {
        afternoon++;
      } else {
        evening++;
      }
    }
    return {'morning': morning, 'afternoon': afternoon, 'evening': evening};
  }

  DateTime _weekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  List<Map<String, dynamic>> _computeWeeklyCompletion(List<Task> tasks) {
    final today = DateTime.now();
    final monday = _weekStart(today);
    final List<Map<String, dynamic>> result = [];

    for (int w = 3; w >= 0; w--) {
      final weekStart = monday.subtract(Duration(days: w * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekTasks = tasks.where((t) {
        return t.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(weekEnd);
      }).toList();

      final completed = weekTasks.where((t) => t.isCompleted).length;
      final total = weekTasks.length;
      final rate = total > 0 ? completed / total : 0.0;

      result.add({
        'week': 'W${4 - w}',
        'completed': completed,
        'total': total,
        'rate': rate,
      });
    }

    return result;
  }

  Future<void> _loadStreakPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    streak = prefs.getInt('streak') ?? 0;
    bestStreak = prefs.getInt('bestStreak') ?? 0;
    final lastPerfectDayStr = prefs.getString('lastPerfectDay');
    if (lastPerfectDayStr != null) {
      lastPerfectDay = DateTime.tryParse(lastPerfectDayStr);
    }
    final historyJson = prefs.getString('streakHistory');
    if (historyJson != null) {
      streakHistory = (jsonDecode(historyJson) as List).cast<String>();
    }
  }
}

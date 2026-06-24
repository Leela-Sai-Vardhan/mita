import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/models/task_model.dart';
import '../services/notification_service.dart';
import '../services/json_storage_service.dart';
import '../services/rate_prompt_service.dart';
import '../core/streak_milestones.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _todayTasks = [];
  List<Task> _allTasks = [];
  int _streak = 0;
  int _bestStreak = 0;
  bool _isLoading = true;
  DateTime? _lastPerfectDay;
  int _todayExtensionUsed = 0;
  bool _isStreakFrozen = false;
  int? _streakFrozenWeek;
  Set<int> _earnedMilestones = {};
  List<String> _streakHistory = [];
  int? _pendingMilestoneCelebration;

  List<Task> get todayTasks => _todayTasks;
  List<Task> get allTasks => _allTasks;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  DateTime? get lastPerfectDay => _lastPerfectDay;
  bool get isLoading => _isLoading;
  int get todayExtensionUsed => _todayExtensionUsed;
  bool get isStreakFrozen => _isStreakFrozen;
  int? get streakFrozenWeek => _streakFrozenWeek;
  Set<int> get earnedMilestones => _earnedMilestones;
  List<String> get streakHistory => _streakHistory;
  int? get pendingMilestoneCelebration => _pendingMilestoneCelebration;
  String get streakEmoji => _isStreakFrozen ? '⏳' : '🔥';

  bool get isPerfectDay => _todayTasks.length >= 3 && _todayTasks.where((t) => t.isCompleted).length >= 3;
  void clearMilestoneCelebration() {
    _pendingMilestoneCelebration = null;
    notifyListeners();
  }

  bool get isFullPerfectDay => _todayTasks.isNotEmpty && _todayTasks.every((t) => t.isCompleted);
  int get completedCount => _todayTasks.where((t) => t.isCompleted).length;
  bool get canAddTask => _todayTasks.length < 5;
  bool get canAddRegularTask => _todayTasks.length < 3;
  bool get canExtendTask => _todayTasks.length >= 3 && _todayTasks.length < 5 && _todayExtensionUsed < 2;
  int get remainingSlots => 5 - _todayTasks.length;

  void grantExtensionSlot() {
    if (_todayExtensionUsed < 2) {
      _todayExtensionUsed++;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('todayExtensionUsed', _todayExtensionUsed);
      });
      notifyListeners();
    }
  }

  DateTime get endOfDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  double get timeRemainingPercent {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final totalSeconds = endOfDay.difference(startOfDay).inSeconds;
    final remainingSeconds = endOfDay.difference(now).inSeconds;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  int get secondsRemainingToday {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now).inSeconds;
  }

  TaskProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Log diagnostics at startup
      try {
        final diag = await DatabaseHelper.instance.getDiagnostics();
        debugPrint('[TaskProvider] 📊 DB Diagnostics: $diag');
      } catch (e) {
        debugPrint('[TaskProvider] Diagnostics failed: $e');
      }

      // Load tasks first — most critical operation
      await _loadTasks();
      debugPrint('[TaskProvider] ✅ Today tasks loaded: ${_todayTasks.length}');
      
      // Load all tasks for history/stats
      await _loadAllTasks();
      debugPrint('[TaskProvider] ✅ All tasks loaded: ${_allTasks.length}');

      // Load streak — non-critical, isolated
      try {
        await _loadStreak();
        await _checkStreakFreeze();
      } catch (e) {
        debugPrint('[TaskProvider] ⚠️ Streak load failed (non-fatal): $e');
      }

      // Load extension status — non-critical, isolated
      try {
        await _loadExtensionStatus();
      } catch (e) {
        debugPrint('[TaskProvider] ⚠️ Extension status load failed (non-fatal): $e');
      }

      // Schedule notifications — non-critical, isolated
      try {
        await _updateEndOfDayReminder();
      } catch (e) {
        debugPrint('[TaskProvider] ⚠️ End-of-day reminder failed (non-fatal): $e');
      }

      try {
        await updateHomeWidget();
      } catch (e) {
        debugPrint('[TaskProvider] ⚠️ Home widget update failed (non-fatal): $e');
      }

      try {
        await _scheduleWeeklyNotification();
      } catch (e) {
        debugPrint('[TaskProvider] ⚠️ Weekly notification failed (non-fatal): $e');
      }
    } catch (e, stackTrace) {
      debugPrint('[TaskProvider] ❌ CRITICAL error in loadData: $e\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadExtensionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    final savedDate = prefs.getString('extensionDate');
    
    if (savedDate != todayKey) {
      _todayExtensionUsed = 0;
      await prefs.setInt('todayExtensionUsed', 0);
      await prefs.setString('extensionDate', todayKey);
    } else {
      _todayExtensionUsed = prefs.getInt('todayExtensionUsed') ?? 0;
    }
  }

  Future<void> _scheduleWeeklyNotification() async {
    final thisWeek = getWeeklyStats();
    final lastWeekStart = getWeekStart(DateTime.now()).subtract(const Duration(days: 7));
    final lastWeek = getWeeklyStats(weekStart: lastWeekStart);
    
    int comparison = 0;
    if (lastWeek.tasksCompleted > 0) {
      comparison = ((thisWeek.tasksCompleted - lastWeek.tasksCompleted) / lastWeek.tasksCompleted * 100).round();
    }
    
    await NotificationService().scheduleWeeklySummaryNotification(
      tasksCompleted: thisWeek.tasksCompleted,
      perfectDays: thisWeek.perfectDays,
      comparison: comparison,
    );
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _getIsoWeek(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final weekOfYear = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekOfYear;
  }

  Future<void> _saveStreakPrefs([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setInt('streak', _streak);
    await p.setInt('bestStreak', _bestStreak);
    if (_lastPerfectDay != null) {
      await p.setString('lastPerfectDay', _getDateKey(_lastPerfectDay!));
    } else {
      await p.remove('lastPerfectDay');
    }
    await p.setBool('isStreakFrozen', _isStreakFrozen);
    if (_streakFrozenWeek != null) {
      await p.setInt('streakFrozenWeek', _streakFrozenWeek!);
    } else {
      await p.remove('streakFrozenWeek');
    }
  }

  Future<void> _loadTasks() async {
    final now = DateTime.now();
    _todayTasks = await DatabaseHelper.instance.getTasksForDate(now);
  }

  Future<void> _loadAllTasks() async {
    _allTasks = await DatabaseHelper.instance.getAllTasks();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt('streak') ?? 0;
    _bestStreak = prefs.getInt('bestStreak') ?? 0;
    final lastPerfectDayStr = prefs.getString('lastPerfectDay');
    if (lastPerfectDayStr != null) {
      _lastPerfectDay = DateTime.tryParse(lastPerfectDayStr);
    }
    _isStreakFrozen = prefs.getBool('isStreakFrozen') ?? false;
    _streakFrozenWeek = prefs.getInt('streakFrozenWeek');
    if (_streakFrozenWeek == 0) _streakFrozenWeek = null;

    final milestonesJson = prefs.getString('earnedMilestones');
    if (milestonesJson != null) {
      final list = jsonDecode(milestonesJson) as List;
      _earnedMilestones = list.map((e) => e as int).toSet();
    }

    final historyJson = prefs.getString('streakHistory');
    if (historyJson != null) {
      _streakHistory = (jsonDecode(historyJson) as List).cast<String>();
    }
  }

  Future<void> _updateEndOfDayReminder() async {
    await NotificationService().scheduleEndOfDayReminder(_todayTasks);
  }

  Future<void> addTask(String title, {bool isExtended = false, bool preCompleted = false, DateTime? preCompletedAt, TaskRecurrence recurrence = TaskRecurrence.none, List<int>? recurrenceDays}) async {
    if (!canAddTask) return;

    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final newTask = Task(
      title: title,
      date: now,
      deadline: endOfDay,
      isExtended: isExtended,
      isCompleted: preCompleted,
      completedAt: preCompleted ? (preCompletedAt ?? now) : null,
      recurrence: recurrence,
      recurrenceDays: recurrenceDays,
    );

    // Create task with transaction-safe, write-verified insert
    final id = await DatabaseHelper.instance.createTask(newTask);

    // Double-verify: read back from DB to confirm persistence
    final verified = await DatabaseHelper.instance.getTaskSafe(id);
    if (verified == null) {
      debugPrint('[TaskProvider] ⚠️ Write verification failed for id=$id — task may not persist across restart');
    } else {
      debugPrint('[TaskProvider] ✅ Task fully verified in DB: id=$id, title="${verified.title}"');
    }

    final savedTask = newTask.copyWith(id: id);
    _todayTasks.add(savedTask);
    _allTasks.add(savedTask);

    try {
      await NotificationService().scheduleTaskReminder(savedTask);
    } catch (e) {
      debugPrint('[TaskProvider] ⚠️ Task reminder scheduling failed (non-fatal): $e');
    }

    try {
      await _updateEndOfDayReminder();
    } catch (e) {
      debugPrint('[TaskProvider] ⚠️ End-of-day reminder update failed (non-fatal): $e');
    }

    notifyListeners();

    try {
      await updateHomeWidget();
    } catch (e) {
      debugPrint('[TaskProvider] ⚠️ Home widget update failed (non-fatal): $e');
    }

    try {
      await JsonStorageService().saveToJson();
    } catch (e) {
      debugPrint('[TaskProvider] ⚠️ JSON backup failed (non-fatal): $e');
    }
  }

  Future<void> _checkStreakFreeze() async {
    if (_streak <= 0) return;
    if (isPerfectDay) return;

    final String todayStr = _getTodayKey();
    if (_lastPerfectDay != null && _getDateKey(_lastPerfectDay!) == todayStr) return;

    final now = DateTime.now();
    final currentWeek = _getIsoWeek(now);

    if (_streakFrozenWeek == currentWeek) {
      _streak = 0;
      _lastPerfectDay = null;
      _isStreakFrozen = false;
      _streakFrozenWeek = null;
      await _saveStreakPrefs();
      debugPrint('[TaskProvider] 🔴 Streak reset: second freeze this week');
    } else {
      _streakFrozenWeek = currentWeek;
      _isStreakFrozen = true;
      await _saveStreakPrefs();
      debugPrint('[TaskProvider] ⏳ Streak frozen: first miss this week');
    }
  }

  Future<void> toggleTask(Task task) async {
    final now = DateTime.now();
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? now : null,
    );
    await DatabaseHelper.instance.updateTask(updatedTask);

    final allIndex = _allTasks.indexWhere((t) => t.id == task.id);
    if (allIndex != -1) {
      _allTasks[allIndex] = updatedTask;
    }

    final index = _todayTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _todayTasks[index] = updatedTask;
      
      if (isPerfectDay) {
        await _incrementStreak();
      } else {
        await _checkRevertStreak();
      }

      if (updatedTask.isCompleted && task.recurrence != TaskRecurrence.none) {
        await _handleRecurrence(task);
      }
      
      try {
        await _updateEndOfDayReminder();
      } catch (e) {
        debugPrint('[TaskProvider] Error scheduling notification: $e');
      }
    }

    notifyListeners();
    try {
      await updateHomeWidget();
    } catch (e) {
      debugPrint('[TaskProvider] Widget sync failed: $e');
    }
    await JsonStorageService().saveToJson();

    if (updatedTask.isCompleted) {
      _requestInAppReview();
      RatePromptService().incrementTasksCompleted();
    }
  }

  Future<void> _requestInAppReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequested = prefs.getBool('has_requested_first_task_review') ?? false;
      if (!hasRequested) {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          // Delay briefly to allow completion animations to finish smoothly
          await Future.delayed(const Duration(milliseconds: 800));
          await inAppReview.requestReview();
          await prefs.setBool('has_requested_first_task_review', true);
        }
      }
    } catch (e) {
      debugPrint('[InAppReview] Error requesting review: $e');
    }
  }

  Future<void> _handleRecurrence(Task task) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    final existingForTomorrow = _allTasks.any((t) => 
      t.title == task.title && 
      t.date.year == tomorrow.year && 
      t.date.month == tomorrow.month && 
      t.date.day == tomorrow.day &&
      t.date.isAfter(taskDate)
    );
    
    if (existingForTomorrow) return;
    
    DateTime nextDate;
    
    switch (task.recurrence) {
      case TaskRecurrence.daily:
        nextDate = tomorrow;
        break;
      case TaskRecurrence.weekdays:
        nextDate = _getNextWeekday(now);
        break;
      case TaskRecurrence.weekends:
        nextDate = _getNextWeekend(now);
        break;
      case TaskRecurrence.specificDays:
        nextDate = _getNextSpecificDay(now, task.recurrenceDays ?? []);
        break;
      default:
        return;
    }

    if (nextDate.isBefore(DateTime(now.year, now.month, now.day, 12, 0, 0))) {
      nextDate = nextDate.add(const Duration(days: 7));
      final adjusted = _adjustToValidDay(nextDate, task.recurrenceDays ?? []);
      if (adjusted != nextDate) nextDate = adjusted;
    }

    final nextTask = Task(
      title: task.title,
      date: nextDate,
      deadline: DateTime(nextDate.year, nextDate.month, nextDate.day, 23, 59, 59),
      isExtended: false,
      recurrence: task.recurrence,
      recurrenceDays: task.recurrenceDays,
    );

    final id = await DatabaseHelper.instance.createTask(nextTask);
    final savedTask = nextTask.copyWith(id: id);
    _allTasks.add(savedTask);
  }

  DateTime _adjustToValidDay(DateTime date, List<int> validDays) {
    if (validDays.isEmpty) return date;
    while (!validDays.contains(date.weekday)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  DateTime _getNextWeekday(DateTime from) {
    var next = from.add(const Duration(days: 1));
    while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _getNextWeekend(DateTime from) {
    var next = from.add(const Duration(days: 1));
    while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _getNextSpecificDay(DateTime from, List<int> days) {
    if (days.isEmpty) return from.add(const Duration(days: 1));
    
    var next = from.add(const Duration(days: 1));
    while (!days.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<void> _checkRevertStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPerfectDayStr = prefs.getString('lastPerfectDay');
    final String todayStr = _getTodayKey();

    if (lastPerfectDayStr == todayStr) {
      if (_streak > 0) _streak--;
      _lastPerfectDay = null;
      await _saveStreakPrefs(prefs);
    }
  }

  Future<void> _incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPerfectDayStr = prefs.getString('lastPerfectDay');
    final now = DateTime.now();
    final String todayStr = _getTodayKey();

    if (lastPerfectDayStr != todayStr) {
      _streak++;
      await prefs.setInt('streak', _streak);

      if (_streak > _bestStreak) {
        _bestStreak = _streak;
        await prefs.setInt('bestStreak', _bestStreak);
      }

      _lastPerfectDay = now;
      await prefs.setString('lastPerfectDay', todayStr);

      // Unfreeze if frozen
      if (_isStreakFrozen) {
        _isStreakFrozen = false;
        _streakFrozenWeek = null;
        await prefs.remove('streakFrozenWeek');
        await prefs.setBool('isStreakFrozen', false);
      }

      // Track streak history
      if (!_streakHistory.contains(todayStr)) {
        _streakHistory.add(todayStr);
        if (_streakHistory.length > 365) _streakHistory.removeAt(0);
        await prefs.setString('streakHistory', jsonEncode(_streakHistory));
      }

      // Check milestone
      if (StreakMilestones.isMilestoneDay(_streak) && !_earnedMilestones.contains(_streak)) {
        _earnedMilestones.add(_streak);
        await prefs.setString('earnedMilestones', jsonEncode(_earnedMilestones.toList()));
        _pendingMilestoneCelebration = _streak;
      }
    }
  }

  double getWeeklyCompletionRate() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekTasks = _allTasks.where((t) => t.date.isAfter(weekAgo)).toList();
    if (weekTasks.isEmpty) return 0.0;
    final completed = weekTasks.where((t) => t.isCompleted).length;
    return completed / weekTasks.length;
  }

  double getMonthlyCompletionRate() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final monthTasks = _allTasks.where((t) => t.date.isAfter(monthAgo)).toList();
    if (monthTasks.isEmpty) return 0.0;
    final completed = monthTasks.where((t) => t.isCompleted).length;
    return completed / monthTasks.length;
  }

  Future<void> unlockMoreHistory(int additionalDays) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUnlocked = prefs.getInt('unlockedHistoryDays') ?? 7;
    await prefs.setInt('unlockedHistoryDays', currentUnlocked + additionalDays);
    notifyListeners();
  }

  Future<int> getUnlockedHistoryDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('unlockedHistoryDays') ?? 7;
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = 0;
    _bestStreak = 0;
    _lastPerfectDay = null;
    _isStreakFrozen = false;
    _streakFrozenWeek = null;
    _pendingMilestoneCelebration = null;
    await prefs.setInt('streak', 0);
    await prefs.setInt('bestStreak', 0);
    await prefs.remove('lastPerfectDay');
    await prefs.setBool('isStreakFrozen', false);
    await prefs.remove('streakFrozenWeek');
    notifyListeners();
    await JsonStorageService().saveToJson();
  }

  Future<void> clearAllData() async {
    // 1. Delete all tasks from SQLite
    final db = DatabaseHelper.instance;
    final allTasksList = await db.getAllTasks();
    for (final task in allTasksList) {
      if (task.id != null) {
        await db.deleteTask(task.id!);
      }
    }

    // 2. Delete all focus sessions from SQLite
    await db.clearFocusSessions();

    // 3. Clear local JSON storage
    await JsonStorageService().clearJson();

    // 4. Reset SharedPreferences (preserving onboarding status)
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    await prefs.clear();
    if (hasSeenOnboarding) {
      await prefs.setBool('hasSeenOnboarding', true);
    }

    // 5. Reset local memory state
    _todayTasks.clear();
    _allTasks.clear();
    _streak = 0;
    _bestStreak = 0;
    _lastPerfectDay = null;
    _todayExtensionUsed = 0;
    _isStreakFrozen = false;
    _streakFrozenWeek = null;
    _earnedMilestones.clear();
    _streakHistory.clear();
    _pendingMilestoneCelebration = null;

    // 6. Refresh reminders & home widget
    try {
      await NotificationService().scheduleEndOfDayReminder(_todayTasks);
    } catch (_) {}
    try {
      await updateHomeWidget();
    } catch (_) {}

    notifyListeners();
  }

  Map<DateTime, double> getHeatmapData({int days = 90}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final Map<DateTime, List<bool>> dayTaskStatus = {};

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      dayTaskStatus[normalizedDate] = [];
    }

    for (final task in _allTasks) {
      final normalizedTaskDate = DateTime(task.date.year, task.date.month, task.date.day);
      if (normalizedTaskDate.isAfter(startDate) || normalizedTaskDate.isAtSameMomentAs(startDate)) {
        if (dayTaskStatus.containsKey(normalizedTaskDate)) {
          dayTaskStatus[normalizedTaskDate]!.add(task.isCompleted);
        }
      }
    }

    final Map<DateTime, double> heatmap = {};
    for (final entry in dayTaskStatus.entries) {
      final tasks = entry.value;
      if (tasks.isEmpty) {
        heatmap[entry.key] = 0.0;
      } else {
        final completed = tasks.where((t) => t).length;
        heatmap[entry.key] = completed / tasks.length;
      }
    }

    return heatmap;
  }

  Future<Map<DateTime, List<Task>>> getGroupedTasks({int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final Map<DateTime, List<Task>> grouped = {};

    for (final task in _allTasks) {
      if (task.date.isAfter(startDate)) {
        final dateKey = DateTime(task.date.year, task.date.month, task.date.day);
        grouped.putIfAbsent(dateKey, () => []).add(task);
      }
    }

    return grouped;
  }

  int get totalTasksCompleted {
    return _allTasks.where((t) => t.isCompleted).length;
  }

  int get totalTasksCreated {
    return _allTasks.length;
  }

  int get perfectDaysCount {
    final Map<DateTime, List<Task>> grouped = {};
    for (final task in _allTasks) {
      final dateKey = DateTime(task.date.year, task.date.month, task.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }
    
    int perfectDays = 0;
    for (final entry in grouped.entries) {
      final tasks = entry.value;
      if (tasks.length >= 3 && tasks.every((t) => t.isCompleted)) {
        perfectDays++;
      }
    }
    return perfectDays;
  }

  double get averageTasksPerDay {
    if (_allTasks.isEmpty) return 0.0;
    final firstDate = _allTasks.last.date;
    final daysSinceStart = DateTime.now().difference(firstDate).inDays + 1;
    return daysSinceStart > 0 ? _allTasks.length / daysSinceStart : 0.0;
  }

  int get bestDayTasks {
    final Map<DateTime, List<Task>> grouped = {};
    for (final task in _allTasks) {
      final dateKey = DateTime(task.date.year, task.date.month, task.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }
    
    int best = 0;
    for (final entry in grouped.entries) {
      if (entry.value.length > best) {
        best = entry.value.length;
      }
    }
    return best;
  }

  int get todayExtendedCount => _todayTasks.where((t) => t.isExtended).length;

  List<Task> get pendingTasksToday {
    return _todayTasks.where((t) => !t.isCompleted).toList();
  }

  bool get hasPendingTasks => pendingTasksToday.isNotEmpty;

  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;

    await DatabaseHelper.instance.deleteTask(task.id!);
    
    _allTasks.removeWhere((t) => t.id == task.id);
    _todayTasks.removeWhere((t) => t.id == task.id);
    
    if (task.isExtended && _todayExtensionUsed > 0) {
      _todayExtensionUsed--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('todayExtensionUsed', _todayExtensionUsed);
    }

    notifyListeners();
    await updateHomeWidget();
    await JsonStorageService().saveToJson();
  }

  Future<void> updateHomeWidget() async {
    try {
      final completed = _todayTasks.where((t) => t.isCompleted).length;
      final total = _todayTasks.isNotEmpty ? _todayTasks.length : 3;
      
      final streakEmoji = _isStreakFrozen ? '⏳' : '🔥';
      await HomeWidget.saveWidgetData<String>('widget_streak', '$streakEmoji $_streak');
      await HomeWidget.saveWidgetData<String>('widget_progress', '$completed/$total tasks');
      await HomeWidget.saveWidgetData<String>('widget_date', _formatDate());
      
      final taskList = _todayTasks.map((t) => {
        'id': t.id,
        'title': t.title,
        'isCompleted': t.isCompleted,
      }).toList();
      try {
        await HomeWidget.saveWidgetData<String>('widget_task_list', jsonEncode(taskList));
      } catch (e) {
        debugPrint('HomeWidget task list save error: $e');
      }
      
      await HomeWidget.updateWidget(
        androidName: 'HomeWidgetProvider',
      );
    } catch (e) {
      debugPrint('HomeWidget update error: $e');
    }
  }
  
  String _formatDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  DateTime getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  WeeklyStats getWeeklyStats({DateTime? weekStart}) {
    final targetWeekStart = weekStart ?? _getWeekStart(DateTime.now());
    
    int tasksCompleted = 0;
    int totalTasks = 0;
    int perfectDays = 0;
    int daysWithActivity = 0;
    
    for (int i = 0; i < 7; i++) {
      final day = targetWeekStart.add(Duration(days: i));
      if (day.isAfter(DateTime.now())) break;
      
      final dayTasks = _allTasks.where((t) {
        if (t.completedAt == null) return false;
        final completed = t.completedAt!;
        return completed.year == day.year && 
               completed.month == day.month && 
               completed.day == day.day;
      }).toList();
      
      if (dayTasks.isNotEmpty) {
        daysWithActivity++;
        final completedCount = dayTasks.where((t) => t.isCompleted).length;
        tasksCompleted += completedCount;
        totalTasks += dayTasks.length;
        if (completedCount >= 3 && dayTasks.length >= 3) {
          perfectDays++;
        }
      }
    }
    
    return WeeklyStats(
      weekStart: targetWeekStart,
      tasksCompleted: tasksCompleted,
      totalTasks: totalTasks,
      perfectDays: perfectDays,
      daysWithActivity: daysWithActivity,
    );
  }

  int getWeeklyComparison() {
    final thisWeek = getWeeklyStats();
    final lastWeekStart = _getWeekStart(DateTime.now()).subtract(const Duration(days: 7));
    final lastWeek = getWeeklyStats(weekStart: lastWeekStart);
    
    if (lastWeek.tasksCompleted == 0) return 0;
    
    final diff = thisWeek.tasksCompleted - lastWeek.tasksCompleted;
    return ((diff / lastWeek.tasksCompleted) * 100).round();
  }

  bool shouldShowWeeklySummary() {
    final now = DateTime.now();
    return now.weekday == 1;
  }

  Future<void> markWeeklySummaryShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'weeklySummary_${today.year}_${_getWeekStart(today).millisecondsSinceEpoch}';
    await prefs.setBool(key, true);
  }

  Future<bool> hasWeeklySummaryBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'weeklySummary_${today.year}_${_getWeekStart(today).millisecondsSinceEpoch}';
    return prefs.getBool(key) ?? false;
  }
}

class WeeklyStats {
  final DateTime weekStart;
  final int tasksCompleted;
  final int totalTasks;
  final int perfectDays;
  final int daysWithActivity;

  WeeklyStats({
    required this.weekStart,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.perfectDays,
    required this.daysWithActivity,
  });

  double get completionRate => totalTasks > 0 ? tasksCompleted / totalTasks : 0;
}
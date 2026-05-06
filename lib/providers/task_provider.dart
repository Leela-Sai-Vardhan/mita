import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../data/models/task_model.dart';
import '../services/notification_service.dart';
import '../services/json_storage_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _todayTasks = [];
  List<Task> _allTasks = [];
  int _streak = 0;
  int _bestStreak = 0;
  bool _isLoading = true;
  DateTime? _lastPerfectDay;
  int _todayExtensionUsed = 0;

  List<Task> get todayTasks => _todayTasks;
  List<Task> get allTasks => _allTasks;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  DateTime? get lastPerfectDay => _lastPerfectDay;
  bool get isLoading => _isLoading;
  int get todayExtensionUsed => _todayExtensionUsed;

  bool get isPerfectDay => _todayTasks.length >= 3 && _todayTasks.where((t) => t.isCompleted).length == 3 && _todayTasks.length <= 3;
  bool get isFullPerfectDay => _todayTasks.isNotEmpty && _todayTasks.every((t) => t.isCompleted);
  int get completedCount => _todayTasks.where((t) => t.isCompleted).length;
  bool get canAddTask => _todayTasks.length < 5;
  bool get canAddRegularTask => _todayTasks.length < 3;
  bool get canExtendTask => _todayTasks.length >= 3 && _todayTasks.length < 5 && _todayExtensionUsed < 2;
  int get remainingSlots => 5 - _todayTasks.length;

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
      await _loadTasks();
      await _loadStreak();
      await _loadAllTasks();
      await _loadExtensionStatus();

      await _updateEndOfDayReminder();
    } catch (e, stackTrace) {
      debugPrint('[TaskProvider] Error in loadData: $e\n$stackTrace');
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

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

    final id = await DatabaseHelper.instance.createTask(newTask);
    final savedTask = newTask.copyWith(id: id);
    _todayTasks.add(savedTask);
    _allTasks.add(savedTask); // Update full history immediately

    if (isExtended) {
      final prefs = await SharedPreferences.getInstance();
      _todayExtensionUsed++;
      await prefs.setInt('todayExtensionUsed', _todayExtensionUsed);
    }

    await NotificationService().scheduleTaskReminder(savedTask);
    await _updateEndOfDayReminder();

    notifyListeners();
    await JsonStorageService().saveToJson();
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
    await JsonStorageService().saveToJson();
  }

  Future<void> _handleRecurrence(Task task) async {
    final now = DateTime.now();
    DateTime nextDate;
    
    switch (task.recurrence) {
      case TaskRecurrence.daily:
        nextDate = now.add(const Duration(days: 1));
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
    final now = DateTime.now();
    final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (lastPerfectDayStr == todayStr) {
      if (_streak > 0) _streak--;
      await prefs.setInt('streak', _streak);
      
      // If we revert, we remove today's lastPerfectDay marker. 
      // The actual previous perfect day is lost from prefs, so we just clear it or leave it null.
      // Next time they get a perfect day, it will increment again.
      _lastPerfectDay = null;
      await prefs.remove('lastPerfectDay');
    }
  }

  Future<void> _incrementStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPerfectDayStr = prefs.getString('lastPerfectDay');
    final now = DateTime.now();
    final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (lastPerfectDayStr != todayStr) {
      _streak++;
      await prefs.setInt('streak', _streak);

      if (_streak > _bestStreak) {
        _bestStreak = _streak;
        await prefs.setInt('bestStreak', _bestStreak);
      }

      _lastPerfectDay = now;
      await prefs.setString('lastPerfectDay', todayStr);
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
    await prefs.setInt('streak', 0);
    await prefs.setInt('bestStreak', 0);
    await prefs.remove('lastPerfectDay');
    notifyListeners();
    await JsonStorageService().saveToJson();
  }

  Map<DateTime, bool> getHeatmapData({int days = 30}) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final Map<DateTime, bool> heatmap = {};

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      heatmap[normalizedDate] = false;
    }

    for (final task in _allTasks) {
      final normalizedTaskDate = DateTime(task.date.year, task.date.month, task.date.day);
      if (normalizedTaskDate.isAfter(startDate) || normalizedTaskDate.isAtSameMomentAs(startDate)) {
        if (heatmap.containsKey(normalizedTaskDate)) {
          heatmap[normalizedTaskDate] = heatmap[normalizedTaskDate]! || task.isCompleted;
        }
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
    await JsonStorageService().saveToJson();
  }
}
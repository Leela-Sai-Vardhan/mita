import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/models/focus_session_model.dart';
import '../services/pomodoro_timer_service.dart';
import '../services/notification_service.dart';

class PomodoroProvider extends ChangeNotifier {
  final PomodoroTimerService timer = PomodoroTimerService();
  FocusSession? _currentSession;
  int _sessionCount = 0;
  int _taskId = 0;
  String _taskTitle = '';

  PomodoroProvider() {
    timer.stateStream.listen(_onStateChange);
    timer.tickStream.listen((_) => notifyListeners());
  }

  int get taskId => _taskId;
  String get taskTitle => _taskTitle;
  bool get hasActiveSession => timer.state != TimerState.idle;

  /// Configure for a new task. Only call when no timer is active,
  /// or use [stopAndSwitch] to explicitly stop first.
  Future<void> configure(int taskId, String taskTitle) async {
    timer.skipBreak();
    _taskId = taskId;
    _taskTitle = taskTitle;
    _currentSession = null;
    try {
      _sessionCount = await DatabaseHelper.instance.getFocusSessionCount(taskId);
    } catch (_) {
      _sessionCount = 0;
    }
    notifyListeners();
  }

  /// Stop any running session and switch to a new task.
  Future<void> stopAndSwitch(int newTaskId, String newTitle) async {
    if (hasActiveSession) {
      await stop();
    }
    await configure(newTaskId, newTitle);
  }

  bool get isRunning => timer.state == TimerState.running;
  bool get isPaused => timer.state == TimerState.paused;
  bool get isBreak => timer.state == TimerState.breakMode;
  bool get isReady => timer.state == TimerState.idle;
  int get sessionCount => _sessionCount;

  Future<void> start({int durationSec = 1500}) async {
    _sessionCount++;
    await timer.start(taskId: taskId, durationSec: durationSec);
    _currentSession = FocusSession(
      taskId: taskId,
      startedAt: DateTime.now(),
      durationSec: durationSec,
    );
    try {
      await NotificationService().scheduleFocusNotification(
        Duration(seconds: durationSec),
        taskTitle,
      );
    } catch (e) {
      debugPrint('[PomodoroProvider] Notification scheduling error: $e');
    }
    notifyListeners();
  }

  void pause() {
    timer.pause();
    try {
      NotificationService().cancelFocusNotification();
    } catch (e) {
      debugPrint('[PomodoroProvider] Notification cancel error: $e');
    }
  }

  void resume() {
    timer.resume();
    try {
      NotificationService().scheduleFocusNotification(
        Duration(seconds: timer.remaining),
        taskTitle,
      );
    } catch (e) {
      debugPrint('[PomodoroProvider] Notification schedule error: $e');
    }
  }

  Future<void> _reloadSessionCount() async {
    try {
      _sessionCount = await DatabaseHelper.instance.getFocusSessionCount(taskId);
    } catch (_) {
      _sessionCount = 0;
    }
    notifyListeners();
  }

  Future<void> resetToReady() async {
    await _saveSession(completed: false);
    timer.skipBreak();
    _currentSession = null;
    await _reloadSessionCount();
    try {
      NotificationService().cancelFocusNotification();
    } catch (e) {
      debugPrint('[PomodoroProvider] Notification cancel error: $e');
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _saveSession(completed: false);
    timer.stop();
    _currentSession = null;
    await _reloadSessionCount();
    try {
      NotificationService().cancelFocusNotification();
    } catch (e) {
      debugPrint('[PomodoroProvider] Notification cancel error: $e');
    }
    notifyListeners();
  }

  void skipBreak() {
    timer.skipBreak();
    _currentSession = null;
    notifyListeners();
  }

  Future<void> clearAll() async {
    timer.stop();
    timer.skipBreak();
    _taskId = 0;
    _taskTitle = '';
    _sessionCount = 0;
    _currentSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  void _onStateChange(TimerState state) {
    if (state == TimerState.breakMode) {
      _saveSession(completed: true).then((_) => _reloadSessionCount());
      try {
        NotificationService().cancelFocusNotification();
      } catch (e) {
        debugPrint('[PomodoroProvider] Notification cancel error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _saveSession({required bool completed}) async {
    if (_currentSession == null) return;
    final session = _currentSession!.copyWith(
      completedAt: DateTime.now(),
      elapsedSec: timer.elapsed,
      completed: completed,
    );
    try {
      await DatabaseHelper.instance.createFocusSession(session);
    } catch (e) {
      debugPrint('[PomodoroProvider] Failed to save session: $e');
    }
  }
}

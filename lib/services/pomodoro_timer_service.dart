import 'dart:async';
import '../data/models/focus_session_model.dart';
import 'notification_service.dart';

enum TimerState { idle, running, paused, breakMode, completed }

class PomodoroTimerService {
  TimerState _state = TimerState.idle;
  Timer? _timer;
  int _elapsed = 0;
  int _duration = 1500;
  int _taskId = 0;
  DateTime? _startedAt;
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();
  final StreamController<int> _tickController = StreamController<int>.broadcast();

  PomodoroTimerService();

  final Stopwatch _stopwatch = Stopwatch();

  Stream<TimerState> get stateStream => _stateController.stream;
  Stream<int> get tickStream => _tickController.stream;
  TimerState get state => _state;
  int get elapsed => _elapsed;
  int get remaining => _duration - _elapsed;
  int get totalDuration => _duration;
  double get progress => _duration > 0 ? _elapsed / _duration : 0.0;

  String get formattedTime {
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  FocusSession? get currentSession {
    if (_state == TimerState.idle) return null;
    return FocusSession(
      taskId: _taskId,
      startedAt: _startedAt ?? DateTime.now().subtract(Duration(seconds: _elapsed)),
      durationSec: _duration,
      elapsedSec: _elapsed,
      completed: _state == TimerState.completed || _state == TimerState.breakMode,
    );
  }

  void _onTick() {
    _elapsed = _stopwatch.elapsed.inSeconds;
    _tickController.add(_elapsed);

    if (_elapsed >= _duration) {
      _timer?.cancel();
      _timer = null;
      _state = TimerState.breakMode;
      _stateController.add(_state);
      _tickController.add(_elapsed);

      NotificationService().showInstantNotification(
        id: 500,
        title: 'Pomodoro Complete!',
        body: 'Time for a break. You earned it!',
      );
    }
  }

  Future<void> start({int taskId = 0, int durationSec = 1500}) async {
    _timer?.cancel();
    _taskId = taskId;
    _duration = durationSec;
    _elapsed = 0;
    _startedAt = DateTime.now();
    _stopwatch..reset()..start();
    _state = TimerState.running;
    _stateController.add(_state);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void pause() {
    if (_state != TimerState.running) return;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    _state = TimerState.paused;
    _stateController.add(_state);
  }

  void resume() {
    if (_state != TimerState.paused) return;
    _state = TimerState.running;
    _stateController.add(_state);
    _startedAt = DateTime.now().subtract(Duration(seconds: _elapsed));
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _state = TimerState.idle;
    _stateController.add(_state);
    _elapsed = 0;
    _duration = 1500;
    _taskId = 0;
    _startedAt = null;
    _stopwatch..stop()..reset();
  }

  void skipBreak() {
    _timer?.cancel();
    _timer = null;
    _state = TimerState.idle;
    _elapsed = 0;
    _duration = 1500;
    _taskId = 0;
    _startedAt = null;
    _stopwatch..stop()..reset();
    _stateController.add(_state);
    _tickController.add(0);
  }

  void dispose() {
    _timer?.cancel();
    _stateController.close();
    _tickController.close();
  }
}

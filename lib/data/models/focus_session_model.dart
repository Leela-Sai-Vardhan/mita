class FocusSession {
  final int? id;
  final int? taskId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSec;
  final int elapsedSec;
  final int interruptions;
  final bool completed;

  FocusSession({
    this.id,
    this.taskId,
    required this.startedAt,
    this.completedAt,
    this.durationSec = 1500,
    this.elapsedSec = 0,
    this.interruptions = 0,
    this.completed = false,
  });

  FocusSession copyWith({
    int? id,
    int? taskId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSec,
    int? elapsedSec,
    int? interruptions,
    bool? completed,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSec: durationSec ?? this.durationSec,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      interruptions: interruptions ?? this.interruptions,
      completed: completed ?? this.completed,
    );
  }

  static String _normalizeDateToString(DateTime dt) {
    final normalized = DateTime(
      dt.year, dt.month, dt.day,
      dt.hour, dt.minute, dt.second, dt.millisecond,
    );
    return normalized.toIso8601String();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'startedAt': _normalizeDateToString(startedAt),
      'completedAt': completedAt != null ? _normalizeDateToString(completedAt!) : null,
      'durationSec': durationSec,
      'elapsedSec': elapsedSec,
      'interruptions': interruptions,
      'completed': completed ? 1 : 0,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      taskId: map['taskId'],
      startedAt: DateTime.parse(map['startedAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      durationSec: map['durationSec'],
      elapsedSec: map['elapsedSec'] ?? 0,
      interruptions: map['interruptions'] ?? 0,
      completed: (map['completed'] ?? 0) == 1,
    );
  }
}

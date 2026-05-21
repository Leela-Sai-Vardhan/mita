enum TaskRecurrence {
  none,
  daily,
  weekdays,
  weekends,
  specificDays,
}

class Task {
  final int? id;
  final String title;
  final bool isCompleted;
  final DateTime date;
  final DateTime? deadline;
  final bool isExtended;
  final DateTime? completedAt;
  final TaskRecurrence recurrence;
  final List<int>? recurrenceDays;

  Task({
    this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.deadline,
    this.isExtended = false,
    this.completedAt,
    this.recurrence = TaskRecurrence.none,
    this.recurrenceDays,
  });

  Task copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    DateTime? deadline,
    bool? isExtended,
    DateTime? completedAt,
    TaskRecurrence? recurrence,
    List<int>? recurrenceDays,
  }) {
    final resolvedIsCompleted = isCompleted ?? this.isCompleted;
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: resolvedIsCompleted,
      date: date ?? this.date,
      deadline: deadline ?? this.deadline,
      isExtended: isExtended ?? this.isExtended,
      completedAt: completedAt ?? (resolvedIsCompleted ? this.completedAt : null),
      recurrence: recurrence ?? this.recurrence,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
    );
  }

  /// Strips timezone info by reconstructing from local components.
  /// This ensures every Android device stores dates identically,
  /// regardless of OS-level timezone formatting (Z, +05:30, +00:00, etc.).
  static String _normalizeDateToString(DateTime dt) {
    // Reconstruct as a local DateTime with no timezone suffix
    final normalized = DateTime(
      dt.year, dt.month, dt.day,
      dt.hour, dt.minute, dt.second, dt.millisecond,
    );
    return normalized.toIso8601String();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'date': _normalizeDateToString(date),
      'deadline': deadline != null ? _normalizeDateToString(deadline!) : null,
      'isExtended': isExtended ? 1 : 0,
      'completedAt': completedAt != null ? _normalizeDateToString(completedAt!) : null,
      'recurrence': recurrence.index,
      'recurrenceDays': recurrenceDays?.join(','),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<int>? days;
    if (map['recurrenceDays'] != null && map['recurrenceDays'].toString().isNotEmpty) {
      days = map['recurrenceDays'].toString().split(',').map((e) => int.parse(e)).toList();
    }
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      date: DateTime.parse(map['date']),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      isExtended: map['isExtended'] == 1,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      recurrence: TaskRecurrence.values[map['recurrence'] as int? ?? TaskRecurrence.none.index],
      recurrenceDays: days,
    );
  }
}

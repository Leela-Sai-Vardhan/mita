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
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      deadline: deadline ?? this.deadline,
      isExtended: isExtended ?? this.isExtended,
      completedAt: completedAt ?? this.completedAt,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'date': date.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'isExtended': isExtended ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
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
      recurrence: TaskRecurrence.values[map['recurrence'] ?? TaskRecurrence.none],
      recurrenceDays: days,
    );
  }
}

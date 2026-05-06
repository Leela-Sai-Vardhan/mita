import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mita.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _migrateDatabase,
    );
  }

  Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
        await db.rawUpdate('''
          UPDATE tasks 
          SET completedAt = date || 'T23:59:59.000'
          WHERE isCompleted = 1 AND completedAt IS NULL
        ''');
      } catch (e) {
        debugPrint('Migration error: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN recurrence INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE tasks ADD COLUMN recurrenceDays TEXT');
      } catch (e) {
        debugPrint('Migration error: $e');
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  isCompleted INTEGER NOT NULL,
  date TEXT NOT NULL,
  deadline TEXT,
  isExtended INTEGER NOT NULL DEFAULT 0,
  completedAt TEXT,
  recurrence INTEGER DEFAULT 0,
  recurrenceDays TEXT
)
''');
  }

  Future<int> createTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<Task> getTask(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      columns: ['id', 'title', 'isCompleted', 'date', 'deadline', 'isExtended', 'completedAt', 'recurrence', 'recurrenceDays'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final db = await instance.database;
    
    // Normalize date to start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      'tasks',
      where: 'date >= ? AND date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'date DESC');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<DateTime>> getUniqueDates() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT date(date) as task_date FROM tasks ORDER BY task_date DESC
    ''');
    return result.map((row) => DateTime.parse(row['task_date'] as String)).toList();
  }

  Future<Map<DateTime, List<Task>>> getTasksGroupedByDate({int? limitDays}) async {
    final db = await instance.database;
    String query = 'SELECT * FROM tasks ORDER BY date DESC';
    if (limitDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      query = 'SELECT * FROM tasks WHERE date >= "${cutoffDate.toIso8601String()}" ORDER BY date DESC';
    }

    final result = await db.rawQuery(query);
    final tasks = result.map((json) => Task.fromMap(json)).toList();

    final Map<DateTime, List<Task>> grouped = {};
    for (final task in tasks) {
      final dateKey = DateTime(task.date.year, task.date.month, task.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }

    return grouped;
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

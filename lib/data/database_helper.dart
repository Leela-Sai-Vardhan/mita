import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/task_model.dart';
import 'models/focus_session_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? _dbPath;

  DatabaseHelper._init();

  /// Returns the resolved database file path (for diagnostics).
  String? get databasePath => _dbPath;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mita.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    _dbPath = path;

    debugPrint('[DB] Opening database at: $path');

    final db = await openDatabase(
      path,
      version: 5, // Bumped for focus_sessions table
      onCreate: _createDB,
      onUpgrade: _migrateDatabase,
      onOpen: (db) async {
        // WAL mode for better concurrent read/write and crash resilience
        // Must use rawQuery instead of execute as PRAGMA journal_mode returns a result set
        await db.rawQuery('PRAGMA journal_mode=WAL');
        // Force full fsync for durability (critical on Samsung)
        await db.rawQuery('PRAGMA synchronous=FULL');
      },
    );

    // Verify schema after open
    await _verifySchema(db);

    return db;
  }

  Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DB] Migrating from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN completedAt TEXT');
        await db.rawUpdate('''
          UPDATE tasks 
          SET completedAt = date || 'T23:59:59.000'
          WHERE isCompleted = 1 AND completedAt IS NULL
        ''');
      } catch (e) {
        // Only ignore "duplicate column" errors
        if (!e.toString().contains('duplicate column')) {
          debugPrint('[DB] Migration v2 CRITICAL error: $e');
          rethrow;
        }
        debugPrint('[DB] Migration v2 skipped (column exists): $e');
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN recurrence INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE tasks ADD COLUMN recurrenceDays TEXT');
      } catch (e) {
        if (!e.toString().contains('duplicate column')) {
          debugPrint('[DB] Migration v3 CRITICAL error: $e');
          rethrow;
        }
        debugPrint('[DB] Migration v3 skipped (columns exist): $e');
      }
    }

    if (oldVersion < 4) {
      // Normalize existing date strings — strip timezone suffixes
      try {
        debugPrint('[DB] Migration v4: Normalizing stored date strings...');
        final rows = await db.query('tasks');
        int normalized = 0;
        for (final row in rows) {
          final id = row['id'] as int;
          final updates = <String, dynamic>{};

          // Normalize 'date' column
          final dateStr = row['date'] as String?;
          if (dateStr != null && _hasTimezoneSuffix(dateStr)) {
            updates['date'] = _stripTimezone(dateStr);
          }

          // Normalize 'deadline' column
          final deadlineStr = row['deadline'] as String?;
          if (deadlineStr != null && _hasTimezoneSuffix(deadlineStr)) {
            updates['deadline'] = _stripTimezone(deadlineStr);
          }

          // Normalize 'completedAt' column
          final completedAtStr = row['completedAt'] as String?;
          if (completedAtStr != null && _hasTimezoneSuffix(completedAtStr)) {
            updates['completedAt'] = _stripTimezone(completedAtStr);
          }

          if (updates.isNotEmpty) {
            await db.update('tasks', updates, where: 'id = ?', whereArgs: [id]);
            normalized++;
          }
        }
        debugPrint('[DB] Migration v4: Normalized $normalized/${rows.length} task date strings');
      } catch (e) {
        debugPrint('[DB] Migration v4 date normalization error: $e');
        // Non-fatal — dates will still parse correctly via DateTime.parse()
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER,
            startedAt TEXT NOT NULL,
            completedAt TEXT,
            durationSec INTEGER NOT NULL,
            elapsedSec INTEGER DEFAULT 0,
            interruptions INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0
          )
        ''');
        debugPrint('[DB] Migration v5: created focus_sessions table');
      } catch (e) {
        if (!e.toString().contains('already exists')) {
          debugPrint('[DB] Migration v5 CRITICAL error: $e');
          rethrow;
        }
        debugPrint('[DB] Migration v5 skipped (table exists): $e');
      }
    }
  }

  /// Check if a date string has a timezone suffix like +05:30 or Z
  bool _hasTimezoneSuffix(String dateStr) {
    return dateStr.endsWith('Z') || 
           RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(dateStr);
  }

  /// Strip timezone suffix and return local datetime string
  String _stripTimezone(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final local = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
      return local.toIso8601String();
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  /// Verify all expected columns exist in the tasks table
  Future<void> _verifySchema(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info('tasks')");
      final columns = result.map((r) => r['name'] as String).toSet();
      
      const expectedColumns = {
        'id', 'title', 'isCompleted', 'date', 'deadline', 
        'isExtended', 'completedAt', 'recurrence', 'recurrenceDays',
      };

      final missing = expectedColumns.difference(columns);
      if (missing.isNotEmpty) {
        debugPrint('[DB] ⚠️ SCHEMA WARNING: Missing columns: $missing');
        // Attempt to add missing columns
        for (final col in missing) {
          try {
            final type = _getColumnType(col);
            await db.execute('ALTER TABLE tasks ADD COLUMN $col $type');
            debugPrint('[DB] ✅ Added missing column: $col');
          } catch (e) {
            debugPrint('[DB] ❌ Failed to add column $col: $e');
          }
        }
      } else {
        debugPrint('[DB] ✅ Schema verified: all ${expectedColumns.length} columns present');
      }
    } catch (e) {
      debugPrint('[DB] Schema verification error: $e');
    }

    // Verify focus_sessions table schema
    try {
      final fsResult = await db.rawQuery("PRAGMA table_info('focus_sessions')");
      if (fsResult.isEmpty) {
        debugPrint('[DB] ⚠️ Table focus_sessions is missing! Creating it...');
        await db.execute('''
          CREATE TABLE focus_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER,
            startedAt TEXT NOT NULL,
            completedAt TEXT,
            durationSec INTEGER NOT NULL,
            elapsedSec INTEGER DEFAULT 0,
            interruptions INTEGER DEFAULT 0,
            completed INTEGER DEFAULT 0
          )
        ''');
        debugPrint('[DB] ✅ Created focus_sessions table.');
      } else {
        final fsColumns = fsResult.map((r) => r['name'] as String).toSet();
        const expectedFsColumns = {
          'id', 'taskId', 'startedAt', 'completedAt',
          'durationSec', 'elapsedSec', 'interruptions', 'completed',
        };
        final fsMissing = expectedFsColumns.difference(fsColumns);
        if (fsMissing.isNotEmpty) {
          debugPrint('[DB] ⚠️ SCHEMA WARNING: focus_sessions missing columns: $fsMissing');
          for (final col in fsMissing) {
            try {
              final type = col == 'completed' || col == 'durationSec' || col == 'elapsedSec' || col == 'interruptions' ? 'INTEGER DEFAULT 0' : 'TEXT';
              await db.execute('ALTER TABLE focus_sessions ADD COLUMN $col $type');
              debugPrint('[DB] ✅ Added missing column to focus_sessions: $col');
            } catch (e) {
              debugPrint('[DB] ❌ Failed to add column $col to focus_sessions: $e');
            }
          }
        } else {
          debugPrint('[DB] ✅ focus_sessions schema verified: ${expectedFsColumns.length} columns present');
        }
      }
    } catch (e) {
      debugPrint('[DB] focus_sessions schema verification error: $e');
    }
  }

  String _getColumnType(String columnName) {
    switch (columnName) {
      case 'completedAt': return 'TEXT';
      case 'recurrence': return 'INTEGER DEFAULT 0';
      case 'recurrenceDays': return 'TEXT';
      case 'isExtended': return 'INTEGER NOT NULL DEFAULT 0';
      default: return 'TEXT';
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

    await db.execute('''
CREATE TABLE focus_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taskId INTEGER,
  startedAt TEXT NOT NULL,
  completedAt TEXT,
  durationSec INTEGER NOT NULL,
  elapsedSec INTEGER DEFAULT 0,
  interruptions INTEGER DEFAULT 0,
  completed INTEGER DEFAULT 0
)
''');
  }

  /// Insert a task inside an explicit transaction for atomic commit safety.
  /// Returns the inserted row ID, or throws if the write could not be verified.
  Future<int> createTask(Task task) async {
    final db = await instance.database;
    
    try {
      final id = await db.transaction<int>((txn) async {
        final insertedId = await txn.insert('tasks', task.toMap());
        
        // Write-verify: confirm the row exists immediately
        final verify = await txn.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [insertedId],
        );
        
        if (verify.isEmpty) {
          throw Exception('[DB] Write verification FAILED for task id=$insertedId');
        }
        
        return insertedId;
      });
      
      debugPrint('[DB] ✅ Task created & verified: id=$id, title="${task.title}"');
      return id;
    } catch (e) {
      debugPrint('[DB] ❌ createTask FAILED: $e');
      
      // Retry once outside transaction as fallback
      try {
        debugPrint('[DB] Retrying createTask with bare insert...');
        final retryId = await db.insert('tasks', task.toMap());
        final verify = await db.query('tasks', where: 'id = ?', whereArgs: [retryId]);
        if (verify.isNotEmpty) {
          debugPrint('[DB] ✅ Retry succeeded: id=$retryId');
          return retryId;
        }
      } catch (retryError) {
        debugPrint('[DB] ❌ Retry also failed: $retryError');
      }
      
      rethrow;
    }
  }

  Future<Task?> getTaskSafe(int id) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Task.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('[DB] getTaskSafe error for id=$id: $e');
      return null;
    }
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

  /// Query tasks for a specific date using normalized date bounds.
  /// Uses both string prefix matching AND range comparison for maximum
  /// compatibility across all Android devices and timezone formats.
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final db = await instance.database;
    
    // Build normalized date bounds (no timezone suffix)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Normalized strings (e.g., '2026-05-21T00:00:00.000')
    final startStr = DateTime(startOfDay.year, startOfDay.month, startOfDay.day)
        .toIso8601String();
    final endStr = DateTime(endOfDay.year, endOfDay.month, endOfDay.day)
        .toIso8601String();

    // Date prefix for LIKE fallback (e.g., '2026-05-21%')
    final datePrefix = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Primary query: range comparison (handles normalized dates)
    // Fallback: LIKE prefix match (handles old timezone-suffixed dates)
    final result = await db.query(
      'tasks',
      where: '(date >= ? AND date < ?) OR (date LIKE ?)',
      whereArgs: [startStr, endStr, '$datePrefix%'],
    );

    // Deduplicate results (in case both conditions match the same row)
    final Map<int, Task> uniqueTasks = {};
    for (final json in result) {
      final task = Task.fromMap(json);
      if (task.id != null) {
        uniqueTasks[task.id!] = task;
      }
    }

    final tasks = uniqueTasks.values.toList();
    debugPrint('[DB] getTasksForDate($datePrefix): found ${tasks.length} tasks');
    return tasks;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks', orderBy: 'date DESC');
    debugPrint('[DB] getAllTasks: ${result.length} total tasks in database');
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
      final cutoffStr = DateTime(cutoffDate.year, cutoffDate.month, cutoffDate.day).toIso8601String();
      query = 'SELECT * FROM tasks WHERE date >= "$cutoffStr" ORDER BY date DESC';
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

  /// Update a task inside an explicit transaction for atomic commit safety.
  Future<int> updateTask(Task task) async {
    final db = await instance.database;

    try {
      final rows = await db.transaction<int>((txn) async {
        return txn.update(
          'tasks',
          task.toMap(),
          where: 'id = ?',
          whereArgs: [task.id],
        );
      });

      debugPrint('[DB] ✅ Task updated: id=${task.id}, rows=$rows');
      return rows;
    } catch (e) {
      debugPrint('[DB] ❌ updateTask FAILED for id=${task.id}: $e');
      // Fallback: bare update without transaction
      try {
        return db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
      } catch (retryError) {
        debugPrint('[DB] ❌ updateTask retry FAILED: $retryError');
        rethrow;
      }
    }
  }

  /// Delete a task inside an explicit transaction.
  Future<int> deleteTask(int id) async {
    final db = await instance.database;

    try {
      final rows = await db.transaction<int>((txn) async {
        return txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
      });
      debugPrint('[DB] ✅ Task deleted: id=$id, rows=$rows');
      return rows;
    } catch (e) {
      debugPrint('[DB] ❌ deleteTask FAILED for id=$id: $e');
      return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    }
  }

  /// Get a diagnostic summary of the database state.
  Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final db = await instance.database;
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      
      final todayPrefix = _todayPrefix();
      final todayResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM tasks WHERE date LIKE '$todayPrefix%'"
      );
      final todayCount = Sqflite.firstIntValue(todayResult) ?? 0;

      return {
        'dbPath': _dbPath,
        'totalTasks': count,
        'todayTasks': todayCount,
        'dbVersion': 5,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  String _todayPrefix() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<int> createFocusSession(FocusSession session) async {
    final db = await instance.database;

    try {
      final id = await db.transaction<int>((txn) async {
        final insertedId = await txn.insert('focus_sessions', session.toMap());

        final verify = await txn.query(
          'focus_sessions',
          where: 'id = ?',
          whereArgs: [insertedId],
        );

        if (verify.isEmpty) {
          throw Exception('[DB] Write verification FAILED for focus_session id=$insertedId');
        }

        return insertedId;
      });

      debugPrint('[DB] Focus session created & verified: id=$id');
      return id;
    } catch (e) {
      debugPrint('[DB] createFocusSession FAILED: $e');

      try {
        debugPrint('[DB] Retrying createFocusSession with bare insert...');
        final retryId = await db.insert('focus_sessions', session.toMap());
        final verify = await db.query('focus_sessions', where: 'id = ?', whereArgs: [retryId]);
        if (verify.isNotEmpty) {
          debugPrint('[DB] Retry succeeded: id=$retryId');
          return retryId;
        }
      } catch (retryError) {
        debugPrint('[DB] Retry also failed: $retryError');
      }

      rethrow;
    }
  }

  Future<List<FocusSession>> getFocusSessions({int? taskId, int? limit}) async {
    final db = await instance.database;

    try {
      final where = taskId != null ? 'taskId = ?' : null;
      final whereArgs = taskId != null ? [taskId] : null;

      final result = await db.query(
        'focus_sessions',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'startedAt DESC',
        limit: limit,
      );

      return result.map((json) => FocusSession.fromMap(json)).toList();
    } catch (e) {
      debugPrint('[DB] getFocusSessions error: $e');
      return [];
    }
  }

  Future<int> getFocusSessionCount(int taskId) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM focus_sessions WHERE taskId = ?',
        [taskId],
      );
      return (result.first['cnt'] as int?) ?? 0;
    } catch (e) {
      debugPrint('[DB] getFocusSessionCount error: $e');
      return 0;
    }
  }

  Future<({int totalSessions, int completedSessions, int totalFocusSec, double avgDurationSec})>
      getFocusSessionStats() async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery('''
        SELECT
          COUNT(*) as totalSessions,
          SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completedSessions,
          COALESCE(SUM(elapsedSec), 0) as totalFocusSec,
          COALESCE(AVG(CASE WHEN completed = 1 THEN elapsedSec END), 0) as avgDurationSec
        FROM focus_sessions
      ''');
      final row = result.first;
      return (
        totalSessions: (row['totalSessions'] as int?) ?? 0,
        completedSessions: (row['completedSessions'] as int?) ?? 0,
        totalFocusSec: (row['totalFocusSec'] as int?) ?? 0,
        avgDurationSec: (row['avgDurationSec'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('[DB] getFocusSessionStats error: $e');
      return (totalSessions: 0, completedSessions: 0, totalFocusSec: 0, avgDurationSec: 0.0);
    }
  }

  DateTime _parseLocalDateOnly(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    return DateTime.parse(dateStr).toLocal();
  }

  Future<Map<DateTime, int>> getFocusTimeByDay(int days) async {
    final db = await instance.database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    try {
      final result = await db.rawQuery('''
        SELECT date(startedAt) as day, COALESCE(SUM(elapsedSec), 0) as totalSec
        FROM focus_sessions
        WHERE startedAt >= ?
        GROUP BY day
        ORDER BY day ASC
      ''', [cutoff.toIso8601String()]);
      return {
        for (final row in result)
          _parseLocalDateOnly(row['day'] as String): (row['totalSec'] as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('[DB] getFocusTimeByDay error: $e');
      return {};
    }
  }

  Future<Map<DateTime, int>> getSessionCountByDay(int days) async {
    final db = await instance.database;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    try {
      final result = await db.rawQuery('''
        SELECT date(startedAt) as day, COUNT(*) as sessionCount
        FROM focus_sessions
        WHERE startedAt >= ?
        GROUP BY day
        ORDER BY day ASC
      ''', [cutoff.toIso8601String()]);
      return {
        for (final row in result)
          _parseLocalDateOnly(row['day'] as String): (row['sessionCount'] as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('[DB] getSessionCountByDay error: $e');
      return {};
    }
  }

  Future<Map<DateTime, int>> getFocusTimeByWeek(int weeks) async {
    final db = await instance.database;
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    try {
      final result = await db.rawQuery('''
        SELECT
          date(startedAt, 'weekday 0', '-7 days') as weekStart,
          COALESCE(SUM(elapsedSec), 0) as totalSec
        FROM focus_sessions
        WHERE startedAt >= ?
        GROUP BY weekStart
        ORDER BY weekStart ASC
      ''', [cutoff.toIso8601String()]);
      return {
        for (final row in result)
          _parseLocalDateOnly(row['weekStart'] as String): (row['totalSec'] as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('[DB] getFocusTimeByWeek error: $e');
      return {};
    }
  }

  Future<int> clearFocusSessions() async {
    final db = await instance.database;
    try {
      final rows = await db.transaction<int>((txn) async {
        return await txn.delete('focus_sessions');
      });
      debugPrint('[DB] ✅ All focus sessions deleted: rows=$rows');
      return rows;
    } catch (e) {
      debugPrint('[DB] ❌ clearFocusSessions FAILED: $e');
      return await db.delete('focus_sessions');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

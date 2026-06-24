import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/database_helper.dart';
import '../data/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<String> exportData() async {
    final db = DatabaseHelper.instance;
    final tasks = await db.getAllTasks();
    
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt('streak') ?? 0;
    final bestStreak = prefs.getInt('bestStreak') ?? 0;
    final lastPerfectDay = prefs.getString('lastPerfectDay');
    final isStreakFrozen = prefs.getBool('isStreakFrozen') ?? false;
    final streakFrozenWeek = prefs.getInt('streakFrozenWeek');
    final earnedMilestones = prefs.getString('earnedMilestones');
    final streakHistory = prefs.getString('streakHistory');
    final notificationHour = prefs.getInt('notificationHour') ?? 9;
    final notificationMinute = prefs.getInt('notificationMinute') ?? 0;

    final exportData = {
      'version': '1.1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => {
        'title': t.title,
        'isCompleted': t.isCompleted,
        'date': t.date.toIso8601String(),
        'deadline': t.deadline?.toIso8601String(),
        'isExtended': t.isExtended,
      }).toList(),
      'stats': {
        'streak': streak,
        'bestStreak': bestStreak,
        'lastPerfectDay': lastPerfectDay,
        'isStreakFrozen': isStreakFrozen,
        'streakFrozenWeek': streakFrozenWeek,
        'earnedMilestones': earnedMilestones,
        'streakHistory': streakHistory,
      },
      'settings': {
        'notificationHour': notificationHour,
        'notificationMinute': notificationMinute,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'mita_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  Future<void> shareExport() async {
    final filePath = await exportData();
    await Share.shareXFiles([XFile(filePath)], text: 'Mita Backup');
  }

  Future<String> saveToDownloads() async {
    final filePath = await exportData();
    
    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsPath = directory.path.replaceFirst(RegExp(r'/Android/data/.*'), '/Downloads');
          final fileName = 'mita_backup_${DateTime.now().millisecondsSinceEpoch}.json';
          final newFile = File('$downloadsPath/$fileName');
          await newFile.writeAsString(await File(filePath).readAsString());
          return newFile.path;
        }
      } catch (e) {
        // Fall back to app documents
      }
    }
    return filePath;
  }

  Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final tasksData = data['tasks'] as List<dynamic>;
      final statsData = data['stats'] as Map<String, dynamic>?;
      final settingsData = data['settings'] as Map<String, dynamic>?;

      final db = DatabaseHelper.instance;

      // Clear existing tasks
      final existingTasks = await db.getAllTasks();
      for (final task in existingTasks) {
        if (task.id != null) {
          await db.deleteTask(task.id!);
        }
      }

      // Import tasks
      for (final taskData in tasksData) {
        final task = Task(
          title: taskData['title'] as String,
          isCompleted: taskData['isCompleted'] as bool,
          date: DateTime.parse(taskData['date'] as String),
          deadline: taskData['deadline'] != null 
              ? DateTime.parse(taskData['deadline'] as String) 
              : null,
          isExtended: taskData['isExtended'] as bool? ?? false,
        );
        await db.createTask(task);
      }

      // Import stats
      if (statsData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('streak', statsData['streak'] as int? ?? 0);
        await prefs.setInt('bestStreak', statsData['bestStreak'] as int? ?? 0);
        if (statsData['lastPerfectDay'] != null) {
          await prefs.setString('lastPerfectDay', statsData['lastPerfectDay'] as String);
        }
        await prefs.setBool('isStreakFrozen', statsData['isStreakFrozen'] as bool? ?? false);
        if (statsData['streakFrozenWeek'] != null) {
          await prefs.setInt('streakFrozenWeek', statsData['streakFrozenWeek'] as int);
        }
        if (statsData['earnedMilestones'] != null) {
          await prefs.setString('earnedMilestones', statsData['earnedMilestones'] as String);
        }
        if (statsData['streakHistory'] != null) {
          await prefs.setString('streakHistory', statsData['streakHistory'] as String);
        }
      }

      // Import settings
      if (settingsData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('notificationHour', settingsData['notificationHour'] as int? ?? 9);
        await prefs.setInt('notificationMinute', settingsData['notificationMinute'] as int? ?? 0);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }
    return null;
  }
}
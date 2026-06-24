import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

class JsonStorageService {
  static final JsonStorageService _instance = JsonStorageService._internal();
  factory JsonStorageService() => _instance;
  JsonStorageService._internal();

  static const String _fileName = 'mita_data.json';

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_fileName';
  }

  Future<void> saveToJson() async {
    try {
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
      final notificationHour = prefs.getInt('notificationHour') ?? 7;
      final notificationMinute = prefs.getInt('notificationMinute') ?? 0;

      final exportData = {
        'version': '1.2.0',
        'lastSync': DateTime.now().toIso8601String(),
        'tasks': tasks.map((t) => {
          'id': t.id,
          'title': t.title,
          'isCompleted': t.isCompleted,
          'date': t.date.toIso8601String(),
          'deadline': t.deadline?.toIso8601String(),
          'isExtended': t.isExtended,
          'completedAt': t.completedAt?.toIso8601String(),
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
      final filePath = await getFilePath();
      final file = File(filePath);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('[JsonStorageService] Error saving to JSON: $e');
    }
  }

  Future<void> clearJson() async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[JsonStorageService] Error clearing JSON: $e');
    }
  }

  Future<bool> jsonExists() async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
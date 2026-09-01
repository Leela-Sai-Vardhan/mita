import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  static const String _prefAppOpens = 'telemetry_app_opens';
  static const String _prefActiveDays = 'telemetry_active_days';
  static const String _prefLastActiveDay = 'telemetry_last_active_day';
  static const String _prefPerfectDays = 'telemetry_perfect_days';
  static const String _prefTasksCompleted = 'telemetry_tasks_completed';
  static const String _prefNotifDaily = 'telemetry_notif_daily';
  static const String _prefNotifEod = 'telemetry_notif_end_of_day';
  static const String _prefNotifWeekly = 'telemetry_notif_weekly';
  static const String _prefNotifFocus = 'telemetry_notif_focus';

  static const String notifDaily = 'daily';
  static const String notifEndOfDay = 'end_of_day';
  static const String notifWeekly = 'weekly';
  static const String notifFocus = 'focus';

  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final opens = prefs.getInt(_prefAppOpens) ?? 0;
    final activeDays = prefs.getInt(_prefActiveDays) ?? 0;
    final lastActive = prefs.getString(_prefLastActiveDay);
    await prefs.setInt(_prefAppOpens, opens + 1);
    if (lastActive != today) {
      await prefs.setInt(_prefActiveDays, activeDays + 1);
      await prefs.setString(_prefLastActiveDay, today);
    }
    _flushSoon();
  }

  Future<void> recordNotificationFired(String kind) async {
    final prefs = await SharedPreferences.getInstance();
    final key = switch (kind) {
      notifDaily => _prefNotifDaily,
      notifEndOfDay => _prefNotifEod,
      notifWeekly => _prefNotifWeekly,
      notifFocus => _prefNotifFocus,
      _ => _prefNotifDaily,
    };
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
    _flushSoon();
  }

  Future<void> recordPerfectDay() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_prefPerfectDays) ?? 0;
    await prefs.setInt(_prefPerfectDays, count + 1);
    _flushSoon();
  }

  Future<void> recordTaskCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_prefTasksCompleted) ?? 0;
    await prefs.setInt(_prefTasksCompleted, count + 1);
    _flushSoon();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _flushing = false;
  String _flushStartedAt = '';

  Future<void> _flushSoon() async {
    if (_flushing) return;
    _flushing = true;
    _flushStartedAt = DateTime.now().toIso8601String();
    await Future.delayed(const Duration(seconds: 2));
    _flushing = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'app_opens': prefs.getInt(_prefAppOpens) ?? 0,
        'active_days': prefs.getInt(_prefActiveDays) ?? 0,
        'perfect_days': prefs.getInt(_prefPerfectDays) ?? 0,
        'tasks_completed': prefs.getInt(_prefTasksCompleted) ?? 0,
        'notif_daily_fired': prefs.getInt(_prefNotifDaily) ?? 0,
        'notif_end_of_day_fired': prefs.getInt(_prefNotifEod) ?? 0,
        'notif_weekly_fired': prefs.getInt(_prefNotifWeekly) ?? 0,
        'notif_focus_fired': prefs.getInt(_prefNotifFocus) ?? 0,
        'last_updated': _flushStartedAt,
      };
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mita_telemetry.json');
      await file.writeAsString(jsonEncode(data));
      debugPrint('[Telemetry] Flushed: $data');
    } catch (e) {
      debugPrint('[Telemetry] Flush failed: $e');
    }
  }
}
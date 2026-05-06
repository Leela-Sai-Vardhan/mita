import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../data/models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  int _notificationTimeHour = 7;
  int _notificationTimeMinute = 0;
  bool _permissionGranted = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[NotificationService] Starting initialization...');
    
    await _requestPermissions();
    debugPrint('[NotificationService] Permissions requested, granted: $_permissionGranted');
    
    await _initTimezone();
    debugPrint('[NotificationService] Timezone initialized');
    
    await _initNotifications();
    debugPrint('[NotificationService] Notifications initialized');
    
    await _loadNotificationTime();
    debugPrint('[NotificationService] Loaded notification time: $_notificationTimeHour:$_notificationTimeMinute');
    
    await scheduleDailyReminder();
    debugPrint('[NotificationService] Daily reminder scheduled');
    
    _isInitialized = true;
    debugPrint('[NotificationService] Initialization complete');
  }

  Future<void> _initTimezone() async {
    tz_data.initializeTimeZones();
    String timeZoneName = await FlutterTimezone.getLocalTimezone();
    const tzAliases = {
      'Asia/Calcutta': 'Asia/Kolkata',
      'Asia/Dacca': 'Asia/Dhaka',
      'Asia/Katmandu': 'Asia/Kathmandu',
      'Asia/Ulaanbaatar': 'Asia/Ulan_Bator',
    };
    timeZoneName = tzAliases[timeZoneName] ?? timeZoneName;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      _permissionGranted = await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationTimeHour = prefs.getInt('notificationHour') ?? 7;
    _notificationTimeMinute = prefs.getInt('notificationMinute') ?? 0;
  }

  Future<void> scheduleDailyReminder() async {
    debugPrint('[NotificationService] Scheduling daily reminder for $_notificationTimeHour:$_notificationTimeMinute');
    
    await _notifications.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _notificationTimeHour,
      _notificationTimeMinute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('[NotificationService] Time already passed today, scheduling for tomorrow: $scheduledDate');
    } else {
      debugPrint('[NotificationService] Scheduling for today: $scheduledDate');
    }

    try {
      await _notifications.zonedSchedule(
      1,
      'Time to focus!',
      'What are your 3 tasks for today?',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminder to complete your tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
      debugPrint('[NotificationService] Daily reminder scheduled successfully!');
    } catch (e) {
      debugPrint('[NotificationService] ERROR scheduling daily reminder: $e');
    }
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    debugPrint('[NotificationService] Setting new notification time: $hour:$minute');
    _notificationTimeHour = hour;
    _notificationTimeMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationHour', hour);
    await prefs.setInt('notificationMinute', minute);
    await scheduleDailyReminder();
  }

  int get notificationHour => _notificationTimeHour;
  int get notificationMinute => _notificationTimeMinute;
  bool get isPermissionGranted => _permissionGranted;

  Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.isCompleted || task.deadline == null) return;

      final deadline = task.deadline!;
      final reminderTime = deadline.subtract(const Duration(hours: 1));
      
      if (reminderTime.isBefore(DateTime.now())) return;

      final taskId = task.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await _notifications.zonedSchedule(
        100 + taskId,
        'Task deadline approaching',
        task.title,
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminders for incomplete tasks',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_$taskId',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling task reminder: $e');
    }
  }

  Future<void> scheduleEndOfDayReminder(List<Task> tasks) async {
    try {
      // ID 2 for end-of-day reminder
      await _notifications.cancel(2);

      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
      if (incompleteTasks.isEmpty) {
        debugPrint('[NotificationService] All tasks completed, canceling 10 PM reminder.');
        return;
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22, 0); // 10:00 PM

      if (scheduledDate.isBefore(now)) {
        debugPrint('[NotificationService] 10 PM already passed today, skipping end of day reminder.');
        return;
      }

      String body;
      if (incompleteTasks.length == 1) {
        body = 'You have 1 incomplete task: ${incompleteTasks.first.title}';
      } else {
        body = 'You have ${incompleteTasks.length} incomplete tasks remaining today.';
      }

      await _notifications.zonedSchedule(
        2,
        'End of day check-in',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'end_of_day',
            'End of Day Reminders',
            channelDescription: 'Reminders for incomplete tasks at 10 PM',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[NotificationService] Scheduled 10 PM reminder for ${incompleteTasks.length} incomplete tasks.');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling end of day reminder: $e');
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _notifications.cancel(100 + taskId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Instant Notifications',
          channelDescription: 'Instant notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }


}
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../data/models/task_model.dart';
import '../screens/navigation_shell.dart';
import 'telemetry_service.dart';
import 'remote_config_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  int _notificationTimeHour = 7;
  int _notificationTimeMinute = 0;
  bool _permissionGranted = false;
  int? _pendingTabIndex;

  static const String prefDaily = 'notif_daily';
  static const String prefEndOfDay = 'notif_end_of_day';
  static const String prefWeeklySummary = 'notif_weekly_summary';
  static const String prefFocus = 'notif_focus';

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
    _recordTelemetryFromPayload(response.payload);
    _routeFromPayload(response.payload);
  }

  void _recordTelemetryFromPayload(String? payload) {
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.isEmpty || !parts.first.startsWith('tab:')) return;
    if (parts.length < 2) {
      final channel = switch (parts.first.substring(4)) {
        'stats' => TelemetryService.notifWeekly,
        _ => TelemetryService.notifDaily,
      };
      TelemetryService().recordNotificationFired(channel);
      return;
    }
    switch (parts[1]) {
      case 'daily':
        TelemetryService().recordNotificationFired(TelemetryService.notifDaily);
        break;
      case 'weekly':
        TelemetryService().recordNotificationFired(TelemetryService.notifWeekly);
        break;
      case 'end_of_day':
        TelemetryService().recordNotificationFired(TelemetryService.notifEndOfDay);
        break;
      case 'focus':
        TelemetryService().recordNotificationFired(TelemetryService.notifFocus);
        break;
    }
  }

  void _routeFromPayload(String? payload) {
    if (payload == null) return;

    int index = 0;
    if (payload.startsWith('tab:')) {
      final tabPart = payload.substring(4).split('|').first;
      index = switch (tabPart) {
        'history' => 1,
        'stats' => 2,
        'settings' => 3,
        _ => 0,
      };
    }

    final nav = MainNavigationState.navigatorKey.currentState;
    if (nav != null && nav.mounted) {
      nav.goToTab(index);
    } else {
      _pendingTabIndex = index;
    }
  }

  int? get takePendingTab {
    final pending = _pendingTabIndex;
    _pendingTabIndex = null;
    return pending;
  }

  Future<void> _loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationTimeHour = prefs.getInt('notificationHour') ?? 7;
    _notificationTimeMinute = prefs.getInt('notificationMinute') ?? 0;
  }

  Future<void> scheduleDailyReminder() async {
    if (!await notificationEnabled(prefDaily)) {
      await _notifications.cancel(1);
      return;
    }
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
      payload: 'tab:today|daily',
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

  Future<void> requestPermission() async {
    await _requestPermissions();
  }

  /// Maps a local notification pref key to its remote-config reminders key.
  static String? _remoteKeyFor(String key) => switch (key) {
        prefDaily => 'daily',
        prefEndOfDay => 'end_of_day',
        prefWeeklySummary => 'weekly',
        prefFocus => 'focus',
        _ => null,
      };

  /// Whether a reminder channel is allowed by BOTH the local pref and the
  /// remote config. If remote config disables a reminder type, it is off for
  /// everyone regardless of the on-device toggle.
  Future<bool> notificationEnabled(String key) async {
    final remoteKey = _remoteKeyFor(key);
    if (remoteKey != null &&
        !RemoteConfigService.instance.reminderEnabled(remoteKey)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  Future<void> setNotificationEnabled(String key, {required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);

    if (!enabled) {
      switch (key) {
        case prefDaily:
          await _notifications.cancel(1);
          break;
        case prefEndOfDay:
          await _notifications.cancel(20);
          break;
        case prefWeeklySummary:
          await _notifications.cancel(2);
          break;
        case prefFocus:
          await _notifications.cancel(999);
          break;
      }
      return;
    }

    switch (key) {
      case prefDaily:
        await scheduleDailyReminder();
        break;
      default:
        break;
    }
  }

  Future<void> scheduleWeeklySummaryNotification({
    required int tasksCompleted,
    required int perfectDays,
    required int comparison,
  }) async {
    if (!await notificationEnabled(prefWeeklySummary)) {
      await _notifications.cancel(2);
      return;
    }
    await _notifications.cancel(2);
    
    final now = tz.TZDateTime.now(tz.local);
    var monday = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    
    while (monday.weekday != 1) {
      monday = monday.add(const Duration(days: 1));
    }
    
    monday = tz.TZDateTime(
      tz.local,
      monday.year,
      monday.month,
      monday.day,
      9,
      0,
    );
    
    if (monday.isBefore(now)) {
      monday = monday.add(const Duration(days: 7));
    }
    
    String comparisonText = comparison > 0 ? '+$comparison% vs last week' : 
                         comparison < 0 ? '$comparison% vs last week' : 
                         'same as last week';
    
    try {
      await _notifications.zonedSchedule(
        2,
        'Weekly Summary',
        'You completed $tasksCompleted tasks ($comparisonText) and had $perfectDays perfect days!',
        monday,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_summary',
            'Weekly Summaries',
            channelDescription: 'Weekly progress summary notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'tab:stats|weekly',
      );
    } catch (e) {
      debugPrint('[NotificationService] ERROR scheduling weekly summary: $e');
    }
  }

  Future<void> scheduleEndOfDayReminder(List<Task> tasks) async {
    try {
      if (!await notificationEnabled(prefEndOfDay)) {
        await _notifications.cancel(20);
        return;
      }
      // ID 20 for end-of-day reminder (id 2 is reserved for the weekly summary)
      await _notifications.cancel(20);

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
        20,
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
        payload: 'tab:today|end_of_day',
      );
      debugPrint('[NotificationService] Scheduled 10 PM reminder for ${incompleteTasks.length} incomplete tasks.');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling end of day reminder: $e');
    }
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

  Future<void> scheduleFocusNotification(Duration duration, String taskTitle) async {
    try {
      if (!await notificationEnabled(prefFocus)) {
        await _notifications.cancel(999);
        return;
      }
      await _notifications.cancel(999); // ID 999 for focus timer

      final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);

      await _notifications.zonedSchedule(
        999,
        'Focus session complete! ☕',
        'Great job focusing on: $taskTitle',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'focus_reminders',
            'Focus Session Reminders',
            channelDescription: 'Alerts when your Pomodoro focus session finishes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'tab:today|focus',
      );
      debugPrint('[NotificationService] Zoned Focus Notification scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling focus notification: $e');
    }
  }

  Future<void> cancelFocusNotification() async {
    await _notifications.cancel(999);
  }
}
# Mita - OpenCode Context

## Instructions

- **Always run `flutter analyze` (NOT `flutter build` or `flutter debug`) to check for issues**
- Use `flutter analyze` after every code change to ensure code is correct
- For testing on device, use `flutter run` or build release APK

## App Overview

- **Name:** Mita
- **Type:** Flutter mobile app
- **Package:** com.dreamstarx.mita
- **Description:** Micro-task checklist app with 3-5 tasks per day, streak tracking, and local notifications

## Session History

- **Last Session:** 2026-05-06
- **Total Sessions:** 6
- **Completed Tasks:**
  - Phase 1: Data Integration - Real stats from SharedPreferences, real heatmap data
  - Phase 2: AdMob Integration - Interstitial + Rewarded ads with test IDs
  - Phase 3: Refactoring - Extracted common widgets (StatCard, StatRow, RewardButton)
  - Phase 4: Fill Gaps - Created Splash Screen, Settings Screen, Menu Sheet
  - Phase 5: Play Console Release - Signed AAB, custom icon, release keystore
  - Phase 6: Task Extension - Max 5 tasks/day, deadline tracking, end-of-day deadline
  - Phase 7: Local Notifications - flutter_local_notifications, daily reminders, task deadlines
  - Phase 8: Inactivate Ads - Disabled AdMob (kept for future), removed from UI
  - Phase 9: Calendar Heatmap - 7-column calendar view with month navigation
  - Phase 10: Full Stats - Total tasks, completed, perfect days, best day, average
  - Phase 11: Battery Optimization - Settings option to disable battery optimization
  - Phase 12: Data Backup/Restore - Export/Import JSON functionality
  - Phase 13: Test Notification - Button to verify notifications work
  - Phase 14: History Detail - Full screen with task completion times and productivity insights
  - Phase 15: JSON Storage Sync - Hybrid fix for task visibility issue on Samsung devices

## Current Work

- **Status:** Phase 17 Complete - Task Recurrence implemented
- **Focus:** Recurring tasks with daily/weekdays/weekends/specific day options

## Changes Made

### task_model.dart
- Added `deadline` field (DateTime?)
- Added `isExtended` field (bool) - tracks if task is an extended task
- Added `completedAt` field (DateTime?) - tracks when task was completed

### database_helper.dart
- Added `deadline` column to tasks table
- Added `isExtended` column to tasks table
- Added `completedAt` column to tasks table
- Added database migration (version 2) for existing data
- Updated `getTask()` to fetch all columns

### task_provider.dart
- Added task extension logic (max 5 tasks: 3 regular + 2 extended)
- Added deadline tracking with end-of-day deadline
- Added `todayExtensionUsed` counter
- Added `timeRemainingPercent` getter for deadline bar
- Added stats methods: `totalTasksCompleted`, `totalTasksCreated`, `perfectDaysCount`, `averageTasksPerDay`, `bestDayTasks`, `pendingTasksToday`, `hasPendingTasks`
- Updated `toggleTask()` to set `completedAt` when marking complete
- Added integration to schedule End of Day reminder at 10 PM dynamically when tasks are updated
- Fixed streak logic: Properly saves/checks current date (removes ISO formatting bug) and handles decrementing streak if user untoggles a task
- Synchronized `_allTasks` memory cache instantly upon task add/toggle so history/stats UI updates without restarts

### home_screen.dart
- Added deadline progress bar showing time left in day
- Updated task list to show 5 slots (3 regular + 2 extended)
- Updated task cards to show extended tasks with orange styling
- Updated add button to handle extension dialog
- Added extension confirmation dialog with deadline info
- Removed redundant Settings shortcut from the Menu Sheet

### stats_screen.dart
- Added full stats section: Total Tasks, Completed, Perfect Days, Best Day, Average/Day
- Replaced heatmap with calendar view (7-column, month navigation)
- Added month/year header with prev/next navigation
- Removed reward button (ads disabled)
- Added color legend

### history_screen.dart
- Removed ad-based unlock (ads disabled)
- Replaced with free unlock functionality
- Made date cards tappable → navigates to detail screen

### history_detail_screen.dart (NEW)
- Full screen showing detailed information for a specific date
- Day Summary: Total tasks, Completed count, Average time, Completion rate
- Productivity Insight: Morning Champion / Afternoon Achiever / Night Owl / Consistent Worker
- Task list with Created time, Completed time, Duration
- Extended task tags

### settings_screen.dart
- Added NOTIFICATIONS section
- Added Daily Reminder time picker setting (defaults to 7:00 AM)
- Added Battery Optimization dialog with Open Settings button
- Added AutoStart dialog with Open App Info button (for Xiaomi/Oppo/Vivo compatibility)
- Added BACKUP section with Export/Import Data

### notification_service.dart
- Created full notification service using `flutter_local_notifications`
- Default daily reminder set to 7:00 AM
- Schedule smart End-of-Day check-in at 10:00 PM for any incomplete tasks
- Schedule task deadline reminders (1 hour before)
- Uses `inexactAllowWhileIdle` to bypass harsh OEM battery restrictions on Android 14+
- Methods: initialize(), scheduleDailyReminder(), scheduleTaskReminder(), scheduleEndOfDayReminder(), setNotificationTime()

### backup_service.dart (NEW)
- Export data to JSON (tasks + stats + settings)
- Share exported file
- Import data from JSON file
- File picker for import

### main.dart
- Initialized NotificationService
- Disabled AdMob initialization
- Removed interstitial ad loading
- Integrated `in_app_update` for automatic Immediate/Flexible update prompts on app startup

### json_storage_service.dart (NEW - Hybrid Fix)
- Auto-syncs all SQLite data to JSON file on every task change
- Called after addTask(), toggleTask(), resetStreak()
- JSON file location: /Android/data/com.dreamstarx.mita/files/mita_data.json
- clearJson() called when user clears all data

### task_provider.dart
- Added `deleteTask(Task task)` method to delete task and sync JSON

### home_screen.dart
- Changed from StatelessWidget to StatefulWidget
- Added `_showSwipeHint` state for long-press animation
- Replaced task card with Dismissible widget for swipe-to-delete
- Added red background with delete icon on swipe
- Added long-press handler to show "Swipe to delete" hint overlay
- Added Snackbar with Undo action (5 seconds)

### history_detail_screen.dart
- Changed from StatelessWidget to StatefulWidget
- Added `_showSwipeHint` state for long-press animation
- Replaced task card with Dismissible widget for swipe-to-delete
- Added red background with delete icon on swipe
- Added long-press handler to show "Swipe to delete" hint overlay
- Added Snackbar with Undo action (5 seconds)

### AndroidManifest.xml
- Added notification permissions: RECEIVE_BOOT_COMPLETED, VIBRATE, SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS
- Added `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` for reliable alarm catching
- Commented out AdMob meta-data
- Removed broken `workmanager` receiver proxies

## Remaining Issues

- None

## Notes

- Ads are DISABLED but kept in code for future monetization
- Notification settings available in Settings screen
- Calendar allows navigating to previous months
- Extended tasks shown with orange styling and "Extended task" label
- Deadline bar shows remaining time in today with percentage
- History detail screen shows task completion times and productivity insights
- Battery optimization setting helps ensure notifications are delivered
- Data can be exported/imported as JSON for backup/restore
- Swipe-to-delete on tasks (home and history detail screens)
- Long-press on task shows hint animation: "Swipe to delete"
- Snackbar with Undo option (5 seconds) after delete
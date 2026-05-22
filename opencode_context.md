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
- **Total Sessions:** 8
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
  - Phase 16: Swipe-to-delete - Long-press hint, dismissible with undo snackbar
  - Phase 17: Task Recurrence - Daily/weekdays/weekends/custom recurrence options
  - Phase 18: Weekly Summary - Monday stats summary with notification
  - Phase 19: Production Stability - UI/UX improvements, crash fixes, and seamless updates

## Current Work

- **Status:** Phase 20 Complete - Universal Android Compatibility achieved for v1.2.0+6
- **Focus:** Preventing data persistence issues, time zone normalization mismatches, SQLite transaction safety, write-verification, database schema auto-healing, and production releases.

## Changes Made

### task_provider.dart
- Added `getWeeklyStats({weekStart})` - Returns completed tasks, perfect days, completion rate for any week
- Added `getWeeklyComparison()` - Calculates % change vs previous week (+/- value)
- Added `shouldShowWeeklySummary()` - Checks if today is Monday
- Added `markWeeklySummaryShown()` / `hasWeeklySummaryBeenShown()` - Tracks weekly summary dismissal
- Added `_scheduleWeeklyNotification()` - Schedules Monday 9am notification with last week's stats
- Added WeekStart getter for calculating week boundaries
- Integrated weekly notification scheduling in `loadData()` after data loads

### notification_service.dart
- Added `scheduleWeeklySummaryNotification()` - Schedules zoned notification for Mondays at 9am
- Shows tasks completed, perfect days, and week-over-week comparison
- Uses `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime` for weekly repetition
- Creates dedicated channel 'weekly_summary' for these notifications

### stats_screen.dart
- Added weekly summary card UI that appears at top of Stats screen on Mondays
- Shows: Last week's tasks completed, perfect days, completion rate
- Week-over-week comparison with color coding (green for improvement, red for decline, gray for same)
- Dismissible via close button (stores state via SharedPreferences)
- Manual refresh via icon button in title bar (allows replaying summary)
- Gradient accent/success background matching app theme
- Uses existing stat item styling for consistency

### Widget Integration
- Weekly summary scheduled in TaskProvider.loadData() after data loads
- Works with existing notification system (no conflicts)
- Only shows once per week unless dismissed manually
- Settings allow configuring notification time (already existed for daily reminders)

## Remaining Issues

- None

## Notes
- Weekly summary respects user's notification preferences (only fires if enabled)
- Summary shows data for previous Monday-Sunday week
- Comparison calculates percentage change in completed tasks vs previous week
- Notification fires every Monday at 9:00 AM local time
- In-app summary can be dismissed for the week or replayed via refresh icon
- Follows existing code patterns and styling conventions
- Flutter analyze passes (only minor info-level warnings)

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
- Removed `com.google.android.gms.permission.AD_ID` per Play Console policy (no ads)

### Phase 19 Enhancements (v1.1.0+3)
- **main.dart**: Wrapped `NotificationService` initialization in a `try-catch` block to prevent app startup freezes due to Android background constraints.
- **notification_service.dart**: Wrapped reminder scheduling in `try-catch` blocks to prevent execution halts.
- **task_provider.dart**: Prevented past tasks from triggering Perfect Day streak logic or end-of-day reminders when toggled.
- **history_detail_screen.dart**: Wrapped task cards in `GestureDetector` to enable task marking directly from the history view. Uses `Consumer<TaskProvider>` for real-time reactivity.
- **home_screen.dart**: Revamped "Add Task" logic. Empty task slots (`_buildEmptySlot`) are now directly tappable. The "Add Extra Task" button is now visible simultaneously with the "All done" congratulation message.
- **in_app_update**: Added package for immediate/flexible Google Play app updates on startup.

## Phase 20 Enhancements (v1.2.0+6) - Universal Android Compatibility & Reliability
- **task_model.dart**:
  - Implemented timezone-agnostic date normalization (`_normalizeDateToString`) for storing all DateTime values. Reconstructs Local DateTime before serialization to guarantee identical strings across all Android devices regardless of OS-level locale or timezone (e.g. `Z`, `+05:30`, `+00:00`).
  - Fixed standard Dart `copyWith` bug that prevented resetting `completedAt` to `null` when a task is toggled back to incomplete.
  - Fixed database factory parser type cast bug on dynamic `recurrence` values to prevent runtime index type crashes.
- **database_helper.dart**:
  - Bumped database version to `4`.
  - Configured WAL (Write-Ahead Logging) journal mode and forced `PRAGMA synchronous = FULL` for durability and crash resilience against aggressive OEM battery killers (e.g. Samsung Device Care). Fixed Android SQLite database opening crash by executing these statements via `db.rawQuery()` instead of `db.execute()` (which crashed because PRAGMA statements return a result set, throwing `Queries can be performed using SQLiteDatabase query or rawQuery methods only`).
  - Wrapped SQLite write operations (`createTask`, `updateTask`, `deleteTask`) in transactional scopes (`db.transaction()`) with a fallback bare write block in case of transaction failure.
  - Implemented the **Write-Verify** pattern to query the database immediately after writes and confirm records were physically written before returning.
  - Created a database migration to Version 4 that normalizes all pre-existing timezone-suffixed dates already stored in the DB.
  - Implemented a proactive schema-verification check on database startup (`_verifySchema`) to automatically check for all 9 expected columns and auto-heal missing ones to prevent app crashes after updates.
  - Upgraded date-range queries in `getTasksForDate()` to use both prefix `LIKE` comparison and range checking with deduplication to support both older timezone-suffixed date structures and new normalized strings.
  - Created `getDiagnostics()` and `getTaskSafe(id)` methods for detailed monitoring and robust debugging.
- **task_provider.dart**:
  - Isolated non-critical operations (home widget sync, JSON backups, streaks, notifications) inside independent try-catch blocks to prevent critical database routines from failing.
  - Added double write-verification checks upon adding tasks using `DatabaseHelper.instance.getTaskSafe(id)`.
  - Fixed standard Flutter analyze warnings (e.g. `isNotEmpty` check) to achieve zero lint issues.
- **home_screen.dart**:
  - Cleaned up control structure flow braces to resolve lint warnings.
- **pubspec.yaml**:
  - Incremented package version to `1.2.0+6` for production build rollout.

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
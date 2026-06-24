package com.dreamstarx.mita

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "ACTION_TOGGLE_TASK") {
            val taskId = intent.getIntExtra("taskId", -1)
            if (taskId == -1) return

            Log.d("WidgetActionReceiver", "Toggling task ID: $taskId")

            try {
                val dbPath = context.getDatabasePath("mita.db").absolutePath
                val db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READWRITE)

                // 1. Query the current completion state of the task
                var currentIsCompleted = 0
                val taskCursor = db.rawQuery("SELECT isCompleted FROM tasks WHERE id = ?", arrayOf(taskId.toString()))
                if (taskCursor.moveToFirst()) {
                    currentIsCompleted = taskCursor.getInt(0)
                }
                taskCursor.close()

                // 2. Perform transaction-safe toggle write
                val nextIsCompleted = 1 - currentIsCompleted
                val completedAtVal = if (nextIsCompleted == 1) {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())
                } else {
                    null
                }

                db.execSQL(
                    "UPDATE tasks SET isCompleted = ?, completedAt = ? WHERE id = ?",
                    arrayOf(nextIsCompleted, completedAtVal, taskId)
                )

                // 3. Update Streak & Perfect Day logic in Shared Preferences
                try {
                    val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
                    val cal = Calendar.getInstance()
                    cal.set(Calendar.HOUR_OF_DAY, 0)
                    cal.set(Calendar.MINUTE, 0)
                    cal.set(Calendar.SECOND, 0)
                    cal.set(Calendar.MILLISECOND, 0)
                    val startStr = sdf.format(cal.time)
                    cal.add(Calendar.DAY_OF_MONTH, 1)
                    val endStr = sdf.format(cal.time)
                    val datePrefix = startStr.substring(0, 10) // "yyyy-MM-dd"

                    val todayCursor = db.rawQuery(
                        "SELECT isCompleted FROM tasks WHERE (date >= ? AND date < ?) OR (date LIKE ?)",
                        arrayOf(startStr, endStr, "${datePrefix}%")
                    )
                    var todayCount = 0
                    var todayCompletedCount = 0
                    while (todayCursor.moveToNext()) {
                        todayCount++
                        if (todayCursor.getInt(0) == 1) {
                            todayCompletedCount++
                        }
                    }
                    todayCursor.close()

                    // Edit shared preferences synced with Flutter TaskProvider
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val streak = prefs.getInt("flutter.streak", 0)
                    val bestStreak = prefs.getInt("flutter.bestStreak", 0)
                    val lastPerfectDay = prefs.getString("flutter.lastPerfectDay", null)
                    val todayStr = datePrefix

                    val isPerfectDayNow = todayCount == 3 && todayCompletedCount == 3

                    val editor = prefs.edit()
                    if (isPerfectDayNow) {
                        if (lastPerfectDay != todayStr) {
                            val newStreak = streak + 1
                            editor.putInt("flutter.streak", newStreak)
                            editor.putString("flutter.lastPerfectDay", todayStr)
                            if (newStreak > bestStreak) {
                                editor.putInt("flutter.bestStreak", newStreak)
                            }
                            // Save streak to HomeWidget preferences too for instant render
                            editor.putString("flutter.widget_streak", "🔥 $newStreak")
                        }
                    } else {
                        // If unchecking task broke a perfect day achieved today
                        if (lastPerfectDay == todayStr) {
                            val newStreak = Math.max(0, streak - 1)
                            editor.putInt("flutter.streak", newStreak)
                            editor.remove("flutter.lastPerfectDay")
                            editor.putString("flutter.widget_streak", "🔥 $newStreak")
                        }
                    }
                    
                    // Always sync completed tasks progress count to widget prefs
                    editor.putString("flutter.widget_progress", "$todayCompletedCount/$todayCount tasks")
                    editor.apply()
                } catch (pe: Exception) {
                    Log.e("WidgetActionReceiver", "Failed to sync streak prefs: ${pe.message}")
                }

                db.close()
            } catch (e: Exception) {
                Log.e("WidgetActionReceiver", "Database operation failed: ${e.message}")
            }

            // 4. Force widget provider redraw
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, HomeWidgetProvider::class.java)
            )
            val updateIntent = Intent(context, HomeWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(updateIntent)
        }
    }
}

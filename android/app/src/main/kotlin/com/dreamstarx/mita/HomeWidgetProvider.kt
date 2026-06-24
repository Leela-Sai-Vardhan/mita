package com.dreamstarx.mita

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Redraw widgets when requested
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, HomeWidgetProvider::class.java)
            )
            onUpdate(context, manager, ids)
        }
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.mita_widget)
        
        // 1. Sync Streak and Date text values
        val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        val streakText = widgetData.getString("widget_streak", null)
            ?: flutterPrefs.getString("flutter.widget_streak", "🔥 0")
            ?: "🔥 0"
            
        val dateText = widgetData.getString("widget_date", null)
            ?: flutterPrefs.getString("flutter.widget_date", "Today")
            ?: "Today"

        views.setTextViewText(R.id.widget_streak, streakText)
        views.setTextViewText(R.id.widget_date, dateText)

        // 2. Hide all 5 static task rows by default
        val rowIds = arrayOf(R.id.task_row_1, R.id.task_row_2, R.id.task_row_3, R.id.task_row_4, R.id.task_row_5)
        val checkboxIds = arrayOf(R.id.task_checkbox_1, R.id.task_checkbox_2, R.id.task_checkbox_3, R.id.task_checkbox_4, R.id.task_checkbox_5)
        val titleIds = arrayOf(R.id.task_title_1, R.id.task_title_2, R.id.task_title_3, R.id.task_title_4, R.id.task_title_5)

        for (i in 0..4) {
            views.setViewVisibility(rowIds[i], android.view.View.GONE)
        }

        var hasTasks = false
        var boundCount = 0

        // 3. Primary Data Bind: Query direct SQLite database
        try {
            val dbPath = context.getDatabasePath("mita.db").absolutePath
            val db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READONLY)

            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
            val cal = Calendar.getInstance()
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val startStr = sdf.format(cal.time)
            cal.add(Calendar.DAY_OF_MONTH, 1)
            val endStr = sdf.format(cal.time)
            val datePrefix = startStr.substring(0, 10)

            val cursor = db.rawQuery(
                """SELECT id, title, isCompleted FROM tasks 
                   WHERE (date >= ? AND date < ?) OR (date LIKE ?) LIMIT 5""",
                arrayOf(startStr, endStr, "${datePrefix}%")
            )

            while (cursor.moveToNext() && boundCount < 5) {
                hasTasks = true
                val taskId = cursor.getInt(0)
                val title = cursor.getString(1)
                val isCompleted = cursor.getInt(2) == 1

                val rowId = rowIds[boundCount]
                val checkboxId = checkboxIds[boundCount]
                val titleId = titleIds[boundCount]

                views.setViewVisibility(rowId, android.view.View.VISIBLE)
                views.setTextViewText(titleId, title)

                // Render beautiful checkmark or unchecked circle drawable
                if (isCompleted) {
                    views.setImageViewResource(checkboxId, R.drawable.ic_checkbox_checked)
                    views.setTextColor(titleId, android.graphics.Color.parseColor("#666666"))
                } else {
                    views.setImageViewResource(checkboxId, R.drawable.ic_checkbox_unchecked)
                    views.setTextColor(titleId, android.graphics.Color.parseColor("#FFFFFF"))
                }

                // Attach PendingIntent to whole row layout to expand tap target
                val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                    action = "ACTION_TOGGLE_TASK"
                    putExtra("taskId", taskId)
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_IMMUTABLE
                    } else { 0 }
                val pi = PendingIntent.getBroadcast(
                    context, taskId, toggleIntent, flags
                )
                views.setOnClickPendingIntent(rowId, pi)

                boundCount++
            }
            cursor.close()
            db.close()

        } catch (e: Exception) {
            Log.e("HomeWidgetProvider", "Direct SQLite read failed: ${e.message}. Falling back to SharedPreferences JSON.")
            
            // 4. Secondary Fallback Data Bind: Parse serialized JSON list
            try {
                val jsonStr = widgetData.getString("widget_task_list", null)
                if (!jsonStr.isNullOrEmpty()) {
                    val jsonArray = org.json.JSONArray(jsonStr)
                    val limit = Math.min(jsonArray.length(), 5)
                    for (i in 0 until limit) {
                        hasTasks = true
                        val taskObj = jsonArray.getJSONObject(i)
                        val taskId = taskObj.getInt("id")
                        val title = taskObj.getString("title")
                        val isCompleted = taskObj.getBoolean("isCompleted")

                        val rowId = rowIds[boundCount]
                        val checkboxId = checkboxIds[boundCount]
                        val titleId = titleIds[boundCount]

                        views.setViewVisibility(rowId, android.view.View.VISIBLE)
                        views.setTextViewText(titleId, title)

                        if (isCompleted) {
                            views.setImageViewResource(checkboxId, R.drawable.ic_checkbox_checked)
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#666666"))
                        } else {
                            views.setImageViewResource(checkboxId, R.drawable.ic_checkbox_unchecked)
                            views.setTextColor(titleId, android.graphics.Color.parseColor("#FFFFFF"))
                        }

                        val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                            action = "ACTION_TOGGLE_TASK"
                            putExtra("taskId", taskId)
                        }
                        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                PendingIntent.FLAG_IMMUTABLE
                            } else { 0 }
                        val pi = PendingIntent.getBroadcast(
                            context, taskId, toggleIntent, flags
                        )
                        views.setOnClickPendingIntent(rowId, pi)

                        boundCount++
                    }
                }
            } catch (je: Exception) {
                Log.e("HomeWidgetProvider", "JSON fallback binding failed: ${je.message}")
            }
        }

        // Toggles empty state indicator
        if (hasTasks) {
            views.setViewVisibility(R.id.task_list, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.widget_empty, android.view.View.GONE)
        } else {
            views.setViewVisibility(R.id.task_list, android.view.View.GONE)
            views.setViewVisibility(R.id.widget_empty, android.view.View.VISIBLE)
        }

        manager.updateAppWidget(appWidgetId, views)
    }
}
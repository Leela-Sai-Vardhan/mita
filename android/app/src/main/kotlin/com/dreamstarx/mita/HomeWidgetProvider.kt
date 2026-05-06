package com.dreamstarx.mita

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val widgetData = HomeWidgetPlugin.getData(context)
                val views = RemoteViews(context.packageName, R.layout.mita_widget)

                val streak = widgetData.getString("widget_streak", "🔥 0")
                val progress = widgetData.getString("widget_progress", "0/0 tasks")
                val date = widgetData.getString("widget_date", "Today")

                views.setTextViewText(R.id.widget_streak, streak)
                views.setTextViewText(R.id.widget_progress, progress)
                views.setTextViewText(R.id.widget_date, date)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                val views = RemoteViews(context.packageName, R.layout.mita_widget)
                views.setTextViewText(R.id.widget_streak, "🔥 0")
                views.setTextViewText(R.id.widget_progress, "0/0 tasks")
                views.setTextViewText(R.id.widget_date, "Today")
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
}
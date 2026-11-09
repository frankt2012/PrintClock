package com.franktriolo.printclock

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class PrintClockWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val views = PrintWidgetUpdater.build(context)
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }
}

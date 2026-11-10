package com.franktriolo.printclock

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews

object PrintWidgetUpdater {
    fun requestPin(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        if (!manager.isRequestPinAppWidgetSupported) return false

        val provider = ComponentName(context, PrintClockWidgetProvider::class.java)
        return manager.requestPinAppWidget(provider, null, null)
    }

    fun update(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, PrintClockWidgetProvider::class.java)
        )
        if (ids.isEmpty()) return

        val views = build(context)
        ids.forEach { manager.updateAppWidget(it, views) }
    }

    fun build(context: Context): RemoteViews {
        val state = PrintStateStore.read(context)
        val now = System.currentTimeMillis()
        val active = state.isActive(now)
        val finished = state.isFinished(now)

        val views = RemoteViews(context.packageName, R.layout.printclock_widget)
        BitmapFactory.decodeResource(context.resources, R.drawable.app_icon)?.let {
            views.setImageViewBitmap(R.id.widget_icon, it)
        }

        views.setTextViewText(
            R.id.widget_status,
            when {
                active -> "Printing"
                finished -> "Finished"
                else -> "Ready"
            }
        )
        views.setTextColor(
            R.id.widget_status,
            context.getColor(if (finished) R.color.widget_success else R.color.widget_accent)
        )

        views.setTextViewText(
            R.id.widget_finish,
            if (state.hasDuration) PrintTime.clockLabel(state.finishMillis) else "--:--"
        )
        views.setTextColor(
            R.id.widget_finish,
            context.getColor(if (state.hasDuration) R.color.widget_text else R.color.widget_muted)
        )

        views.setTextViewText(
            R.id.widget_day,
            when {
                active -> PrintTime.dayLabel(state.finishMillis, now)
                finished -> "Finished"
                else -> "No print scheduled"
            }
        )

        views.setViewVisibility(
            R.id.widget_separator,
            if (active) View.VISIBLE else View.GONE
        )
        views.setViewVisibility(
            R.id.widget_countdown,
            if (active) View.VISIBLE else View.GONE
        )

        if (active) {
            // Chronometer works in elapsedRealtime, not wall-clock time.
            val remaining = state.finishMillis - now
            val base = SystemClock.elapsedRealtime() + remaining
            views.setChronometerCountDown(R.id.widget_countdown, true)
            views.setChronometer(
                R.id.widget_countdown,
                base,
                "%s remaining",
                true
            )
        }

        val openIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, openIntent)

        return views
    }
}

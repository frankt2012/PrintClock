package com.franktriolo.printclock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val state = PrintStateStore.read(context)
        if (state.isActive()) {
            PrintAlarmScheduler.schedule(context, state.finishMillis)
        } else {
            PrintAlarmScheduler.cancel(context)
        }
        PrintWidgetUpdater.update(context)
    }
}

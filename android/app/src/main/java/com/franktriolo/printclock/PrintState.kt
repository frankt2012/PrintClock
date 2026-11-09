package com.franktriolo.printclock

import android.content.Context

data class PrintState(
    val hours: Int,
    val minutes: Int,
    val startMillis: Long
) {
    val durationMillis: Long
        get() = PrintTime.durationMillis(hours, minutes)

    val hasDuration: Boolean
        get() = durationMillis > 0

    val finishMillis: Long
        get() = startMillis + durationMillis

    fun isActive(nowMillis: Long = System.currentTimeMillis()): Boolean =
        hasDuration && finishMillis > nowMillis

    fun isFinished(nowMillis: Long = System.currentTimeMillis()): Boolean =
        hasDuration && finishMillis <= nowMillis
}

object PrintStateStore {
    const val PREFS = "printclock_state"
    private const val KEY_HOURS = "printHours"
    private const val KEY_MINUTES = "printMinutes"
    private const val KEY_START = "printStart"

    fun read(context: Context): PrintState {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return PrintState(
            hours = prefs.getInt(KEY_HOURS, 0),
            minutes = prefs.getInt(KEY_MINUTES, 0),
            startMillis = prefs.getLong(KEY_START, System.currentTimeMillis())
        )
    }

    fun write(context: Context, state: PrintState) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(KEY_HOURS, state.hours)
            .putInt(KEY_MINUTES, state.minutes)
            .putLong(KEY_START, state.startMillis)
            .apply()
    }
}

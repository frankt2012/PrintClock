package com.franktriolo.printclock

import android.app.Application
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel

class PrintClockViewModel(application: Application) : AndroidViewModel(application) {
    private val prefs =
        application.getSharedPreferences("printclock_state", Context.MODE_PRIVATE)

    var hours by mutableIntStateOf(prefs.getInt(KEY_HOURS, 0))
        private set

    var minutes by mutableIntStateOf(prefs.getInt(KEY_MINUTES, 0))
        private set

    var startMillis by mutableLongStateOf(prefs.getLong(KEY_START, System.currentTimeMillis()))
        private set

    var active by mutableStateOf(false)
        private set

    val durationMillis: Long
        get() = PrintTime.durationMillis(hours, minutes)

    val hasDuration: Boolean
        get() = durationMillis > 0

    val finishMillis: Long
        get() = PrintTime.finishMillis(startMillis, hours, minutes)

    init {
        restore()
    }

    private fun restore() {
        val now = System.currentTimeMillis()
        val savedStart = prefs.getLong(KEY_START, now)
        val savedFinish = savedStart + durationMillis

        if (durationMillis > 0 && savedFinish > now) {
            startMillis = savedStart
            active = true
            PrintAlarmScheduler.schedule(getApplication(), savedFinish)
            return
        }

        // A finished or stale timer should not silently start a new notification.
        hours = 0
        minutes = 0
        startMillis = now
        active = false
        persist()
        PrintAlarmScheduler.cancel(getApplication())
    }

    fun updateHours(value: Int) {
        setDuration(value, minutes)
    }

    fun updateMinutes(value: Int) {
        setDuration(hours, value)
    }

    fun setDuration(newHours: Int, newMinutes: Int) {
        hours = newHours.coerceIn(0, 999)
        minutes = newMinutes.coerceIn(0, 59)
        startMillis = System.currentTimeMillis()
        active = hasDuration
        persist()
        updateAlarm()
    }

    fun resetToNow() {
        startMillis = System.currentTimeMillis()
        active = hasDuration
        persist()
        updateAlarm()
    }

    fun clear() {
        setDuration(0, 0)
    }

    private fun persist() {
        prefs.edit()
            .putInt(KEY_HOURS, hours)
            .putInt(KEY_MINUTES, minutes)
            .putLong(KEY_START, startMillis)
            .apply()
    }

    private fun updateAlarm() {
        if (active && hasDuration) {
            PrintAlarmScheduler.schedule(getApplication(), finishMillis)
        } else {
            PrintAlarmScheduler.cancel(getApplication())
        }
    }

    private companion object {
        const val KEY_HOURS = "printHours"
        const val KEY_MINUTES = "printMinutes"
        const val KEY_START = "printStart"
    }
}

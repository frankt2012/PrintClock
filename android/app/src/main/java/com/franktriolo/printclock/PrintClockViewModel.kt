package com.franktriolo.printclock

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel

class PrintClockViewModel(application: Application) : AndroidViewModel(application) {
    var hours by mutableIntStateOf(0)
        private set

    var minutes by mutableIntStateOf(0)
        private set

    var startMillis by mutableLongStateOf(System.currentTimeMillis())
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
        val app = getApplication<Application>()
        val saved = PrintStateStore.read(app)
        val now = System.currentTimeMillis()

        hours = saved.hours
        minutes = saved.minutes
        startMillis = saved.startMillis

        if (saved.isActive(now)) {
            active = true
            PrintAlarmScheduler.schedule(app, saved.finishMillis)
        } else {
            // A finished or stale timer should not silently start a new notification.
            hours = 0
            minutes = 0
            startMillis = now
            active = false
            persist()
            PrintAlarmScheduler.cancel(app)
        }

        PrintWidgetUpdater.update(app)
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
        PrintStateStore.write(
            getApplication(),
            PrintState(hours = hours, minutes = minutes, startMillis = startMillis)
        )
    }

    private fun updateAlarm() {
        val app = getApplication<Application>()
        if (active && hasDuration) {
            PrintAlarmScheduler.schedule(app, finishMillis)
        } else {
            PrintAlarmScheduler.cancel(app)
        }
        PrintWidgetUpdater.update(app)
    }
}

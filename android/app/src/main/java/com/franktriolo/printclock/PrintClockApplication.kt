package com.franktriolo.printclock

import android.app.Application

class PrintClockApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Notifications.ensureChannel(this)
    }
}

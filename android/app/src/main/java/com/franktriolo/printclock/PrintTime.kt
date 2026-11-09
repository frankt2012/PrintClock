package com.franktriolo.printclock

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.ceil
import kotlin.math.max

object PrintTime {
    fun durationMillis(hours: Int, minutes: Int): Long =
        (max(0, hours) * 60L + max(0, minutes)) * 60_000L

    fun finishMillis(startMillis: Long, hours: Int, minutes: Int): Long =
        startMillis + durationMillis(hours, minutes)

    fun durationLabel(hours: Int, minutes: Int): String {
        val h = max(0, hours)
        val m = max(0, minutes)
        return when {
            h == 0 && m == 0 -> "No print time"
            h == 0 -> "$m min"
            m == 0 -> "$h hr"
            else -> "$h hr $m min"
        }
    }

    fun clockLabel(
        epochMillis: Long,
        zone: ZoneId = ZoneId.systemDefault(),
        locale: Locale = Locale.getDefault()
    ): String = Instant.ofEpochMilli(epochMillis)
        .atZone(zone)
        .format(DateTimeFormatter.ofPattern("h:mm a", locale))

    fun dayLabel(
        finishMillis: Long,
        nowMillis: Long,
        zone: ZoneId = ZoneId.systemDefault(),
        locale: Locale = Locale.getDefault()
    ): String {
        val finish = Instant.ofEpochMilli(finishMillis).atZone(zone).toLocalDate()
        val today = Instant.ofEpochMilli(nowMillis).atZone(zone).toLocalDate()
        return when (finish) {
            today -> "Today"
            today.plusDays(1) -> "Tomorrow"
            today.minusDays(1) -> "Yesterday"
            else -> {
                val pattern = if (finish.year == today.year) "EEEE, MMMM d" else "EEEE, MMMM d, yyyy"
                finish.format(DateTimeFormatter.ofPattern(pattern, locale))
            }
        }
    }

    fun countdownLabel(remainingMillis: Long): String {
        if (remainingMillis <= 0) return "Finished"
        if (remainingMillis < 60_000) return "Less than a minute remaining"

        val totalMinutes = ceil(remainingMillis / 60_000.0).toLong()
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        return when {
            hours > 0 && minutes > 0 -> "$hours hr $minutes min remaining"
            hours > 0 -> "$hours hr remaining"
            else -> "$minutes min remaining"
        }
    }

    fun progress(startMillis: Long, finishMillis: Long, nowMillis: Long): Float {
        val total = finishMillis - startMillis
        if (total <= 0) return 1f
        return ((nowMillis - startMillis).toDouble() / total)
            .coerceIn(0.0, 1.0)
            .toFloat()
    }
}

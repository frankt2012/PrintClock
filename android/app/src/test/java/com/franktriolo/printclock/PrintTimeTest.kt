package com.franktriolo.printclock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.ZoneId
import java.util.Locale

class PrintTimeTest {
    private val utc = ZoneId.of("UTC")
    private val us = Locale.US

    private fun epoch(iso: String): Long = Instant.parse(iso).toEpochMilli()

    @Test
    fun durationConvertsHoursAndMinutesToMillis() {
        assertEquals(16_320_000L, PrintTime.durationMillis(4, 32))
        assertEquals(2_700_000L, PrintTime.durationMillis(0, 45))
        assertEquals(3_600_000L, PrintTime.durationMillis(1, 0))
        assertEquals(0L, PrintTime.durationMillis(0, 0))
        assertEquals(0L, PrintTime.durationMillis(-2, -5))
    }

    @Test
    fun finishAddsDurationToStart() {
        val start = epoch("2026-11-08T14:15:00Z")
        assertEquals(
            epoch("2026-11-08T18:47:00Z"),
            PrintTime.finishMillis(start, 4, 32)
        )
    }

    @Test
    fun finishCrossesMidnight() {
        val start = epoch("2026-11-08T23:30:00Z")
        assertEquals(
            epoch("2026-11-09T02:15:00Z"),
            PrintTime.finishMillis(start, 2, 45)
        )
    }

    @Test
    fun durationLabel() {
        assertEquals("4 hr 32 min", PrintTime.durationLabel(4, 32))
        assertEquals("2 hr", PrintTime.durationLabel(2, 0))
        assertEquals("45 min", PrintTime.durationLabel(0, 45))
        assertEquals("No print time", PrintTime.durationLabel(0, 0))
    }

    @Test
    fun clockLabelUsesTwelveHourLocale() {
        assertEquals(
            "7:48 PM",
            PrintTime.clockLabel(epoch("2026-11-08T19:48:00Z"), utc, us)
        )
    }

    @Test
    fun dayLabelRecognisesTodayTomorrowAndYesterday() {
        val now = epoch("2026-11-08T12:00:00Z")
        assertEquals("Today", PrintTime.dayLabel(epoch("2026-11-08T18:00:00Z"), now, utc, us))
        assertEquals("Tomorrow", PrintTime.dayLabel(epoch("2026-11-09T02:00:00Z"), now, utc, us))
        assertEquals("Yesterday", PrintTime.dayLabel(epoch("2026-11-07T22:00:00Z"), now, utc, us))
    }

    @Test
    fun dayLabelFallsBackToFullDate() {
        assertEquals(
            "Wednesday, November 18",
            PrintTime.dayLabel(
                epoch("2026-11-18T03:00:00Z"),
                epoch("2026-11-08T12:00:00Z"),
                utc,
                us
            )
        )
    }

    @Test
    fun dayLabelIncludesYearForAnotherYear() {
        assertEquals(
            "Saturday, January 2, 2027",
            PrintTime.dayLabel(
                epoch("2027-01-02T03:00:00Z"),
                epoch("2026-11-08T12:00:00Z"),
                utc,
                us
            )
        )
    }

    @Test
    fun countdownText() {
        assertEquals("Finished", PrintTime.countdownLabel(0))
        assertEquals("Finished", PrintTime.countdownLabel(-120_000))
        assertEquals("Less than a minute remaining", PrintTime.countdownLabel(30_000))
        assertEquals("1 min remaining", PrintTime.countdownLabel(60_000))
        assertEquals("2 min remaining", PrintTime.countdownLabel(119_000))
        assertEquals("1 hr remaining", PrintTime.countdownLabel(3_600_000))
        assertEquals("4 hr 32 min remaining", PrintTime.countdownLabel(16_320_000))
        assertEquals("25 hr 1 min remaining", PrintTime.countdownLabel(90_060_000))
    }

    @Test
    fun progressClampsToValidRange() {
        val start = epoch("2026-11-08T12:00:00Z")
        val finish = epoch("2026-11-08T16:00:00Z")
        assertEquals(
            0.25f,
            PrintTime.progress(start, finish, epoch("2026-11-08T13:00:00Z")),
            0.0001f
        )
        assertEquals(0f, PrintTime.progress(start, finish, epoch("2026-11-08T10:00:00Z")))
        assertEquals(1f, PrintTime.progress(start, finish, epoch("2026-11-08T20:00:00Z")))
        assertTrue(PrintTime.progress(start, start, start.plus(1)) == 1f)
    }
}

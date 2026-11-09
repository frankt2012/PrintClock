import Foundation

/// Pure date math and formatting for the print-finish calculator.
public enum PrintTime {
    /// Total print duration in seconds.
    public static func duration(hours: Int, minutes: Int) -> TimeInterval {
        TimeInterval(max(0, hours) * 3600 + max(0, minutes) * 60)
    }

    /// The moment a print started at `start` will be finished.
    public static func finish(start: Date, hours: Int, minutes: Int) -> Date {
        start.addingTimeInterval(duration(hours: hours, minutes: minutes))
    }

    /// Human-readable duration, e.g. "4 hr 32 min".
    public static func durationText(hours: Int, minutes: Int) -> String {
        let hours = max(0, hours)
        let minutes = max(0, minutes)

        switch (hours, minutes) {
        case (0, 0):
            return "No print time"
        case (0, _):
            return "\(minutes) min"
        case (_, 0):
            return "\(hours) hr"
        default:
            return "\(hours) hr \(minutes) min"
        }
    }

    /// Clock time such as "7:48 PM", respecting the user's locale and time zone.
    public static func clockText(
        for date: Date,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Friendly day label for the finish date: "Today", "Tomorrow", or "Wednesday, November 12".
    public static func dayText(
        for date: Date,
        relativeTo now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "EEEEMMMMd" : "EEEEMMMMdyyyy")
        return formatter.string(from: date)
    }

    /// Countdown text for the time left, rounded up to the next minute.
    public static func countdownText(remaining: TimeInterval) -> String {
        guard remaining > 0 else {
            return "Finished"
        }

        guard remaining >= 60 else {
            return "Less than a minute remaining"
        }

        let totalMinutes = Int((remaining / 60).rounded(.up))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes == 0
                ? "\(hours) hr remaining"
                : "\(hours) hr \(minutes) min remaining"
        }

        return "\(minutes) min remaining"
    }

    /// Fraction of the print that has elapsed, clamped to 0...1.
    public static func progress(start: Date, finish: Date, now: Date) -> Double {
        let total = finish.timeIntervalSince(start)
        guard total > 0 else {
            return 1
        }

        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }
}

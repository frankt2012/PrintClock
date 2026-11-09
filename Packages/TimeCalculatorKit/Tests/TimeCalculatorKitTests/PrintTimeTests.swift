import XCTest
@testable import TimeCalculatorKit

final class PrintTimeTests: XCTestCase {
    private let timeZone = TimeZone(identifier: "America/New_York")!
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }

    func testDurationConvertsHoursAndMinutesToSeconds() {
        XCTAssertEqual(PrintTime.duration(hours: 4, minutes: 32), 16_320)
        XCTAssertEqual(PrintTime.duration(hours: 0, minutes: 45), 2_700)
        XCTAssertEqual(PrintTime.duration(hours: 1, minutes: 0), 3_600)
        XCTAssertEqual(PrintTime.duration(hours: 0, minutes: 0), 0)
    }

    func testDurationIgnoresNegativeValues() {
        XCTAssertEqual(PrintTime.duration(hours: -2, minutes: -5), 0)
    }

    func testFinishAddsDurationToStart() {
        let start = makeDate(2026, 11, 8, 14, 15)
        let finish = PrintTime.finish(start: start, hours: 4, minutes: 32)

        XCTAssertEqual(finish, makeDate(2026, 11, 8, 18, 47))
    }

    func testFinishCrossesMidnight() {
        let start = makeDate(2026, 11, 8, 23, 30)
        let finish = PrintTime.finish(start: start, hours: 2, minutes: 45)

        XCTAssertEqual(finish, makeDate(2026, 11, 9, 2, 15))
    }

    func testDurationText() {
        XCTAssertEqual(PrintTime.durationText(hours: 4, minutes: 32), "4 hr 32 min")
        XCTAssertEqual(PrintTime.durationText(hours: 2, minutes: 0), "2 hr")
        XCTAssertEqual(PrintTime.durationText(hours: 0, minutes: 45), "45 min")
        XCTAssertEqual(PrintTime.durationText(hours: 0, minutes: 0), "No print time")
    }

    func testClockTextUsesTwelveHourLocale() {
        let date = makeDate(2026, 11, 8, 19, 48)

        let text = PrintTime.clockText(
            for: date,
            locale: Locale(identifier: "en_US"),
            timeZone: timeZone
        )

        // Newer macOS versions use a narrow no-break space before AM/PM.
        let normalized = text.replacingOccurrences(of: "\u{202F}", with: " ")
        XCTAssertEqual(normalized, "7:48 PM")
    }

    func testDayTextRecognisesTodayTomorrowAndYesterday() {
        let now = makeDate(2026, 11, 8, 12, 0)
        let locale = Locale(identifier: "en_US")

        XCTAssertEqual(
            PrintTime.dayText(for: makeDate(2026, 11, 8, 18, 0), relativeTo: now, calendar: calendar, locale: locale),
            "Today"
        )
        XCTAssertEqual(
            PrintTime.dayText(for: makeDate(2026, 11, 9, 2, 0), relativeTo: now, calendar: calendar, locale: locale),
            "Tomorrow"
        )
        XCTAssertEqual(
            PrintTime.dayText(for: makeDate(2026, 11, 7, 22, 0), relativeTo: now, calendar: calendar, locale: locale),
            "Yesterday"
        )
    }

    func testDayTextFallsBackToFullDate() {
        let now = makeDate(2026, 11, 8, 12, 0)
        let finish = makeDate(2026, 11, 18, 3, 0)

        XCTAssertEqual(
            PrintTime.dayText(
                for: finish,
                relativeTo: now,
                calendar: calendar,
                locale: Locale(identifier: "en_US")
            ),
            "Wednesday, November 18"
        )
    }

    func testDayTextIncludesYearForAnotherYear() {
        let now = makeDate(2026, 11, 8, 12, 0)
        let finish = makeDate(2027, 1, 2, 3, 0)

        XCTAssertEqual(
            PrintTime.dayText(
                for: finish,
                relativeTo: now,
                calendar: calendar,
                locale: Locale(identifier: "en_US")
            ),
            "Saturday, January 2, 2027"
        )
    }

    func testCountdownText() {
        XCTAssertEqual(PrintTime.countdownText(remaining: 0), "Finished")
        XCTAssertEqual(PrintTime.countdownText(remaining: -120), "Finished")
        XCTAssertEqual(PrintTime.countdownText(remaining: 30), "Less than a minute remaining")
        XCTAssertEqual(PrintTime.countdownText(remaining: 60), "1 min remaining")
        XCTAssertEqual(PrintTime.countdownText(remaining: 119), "2 min remaining")
        XCTAssertEqual(PrintTime.countdownText(remaining: 3_600), "1 hr remaining")
        XCTAssertEqual(PrintTime.countdownText(remaining: 16_320), "4 hr 32 min remaining")
        XCTAssertEqual(PrintTime.countdownText(remaining: 90_060), "25 hr 1 min remaining")
    }

    func testProgressClampsToValidRange() {
        let start = makeDate(2026, 11, 8, 12, 0)
        let finish = makeDate(2026, 11, 8, 16, 0)

        XCTAssertEqual(
            PrintTime.progress(start: start, finish: finish, now: makeDate(2026, 11, 8, 13, 0)),
            0.25,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            PrintTime.progress(start: start, finish: finish, now: makeDate(2026, 11, 8, 10, 0)),
            0
        )
        XCTAssertEqual(
            PrintTime.progress(start: start, finish: finish, now: makeDate(2026, 11, 8, 20, 0)),
            1
        )
    }
}

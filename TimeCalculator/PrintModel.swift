import AppKit
import Combine
import Foundation
import TimeCalculatorKit

enum StartMode: String, CaseIterable, Identifiable {
    case now = "Now"
    case custom = "Custom"

    var id: String { rawValue }
}

struct QuickDuration: Identifiable {
    let label: String
    let hours: Int
    let minutes: Int

    var id: String { label }

    static let presets: [QuickDuration] = [
        QuickDuration(label: "30m", hours: 0, minutes: 30),
        QuickDuration(label: "1h", hours: 1, minutes: 0),
        QuickDuration(label: "2h", hours: 2, minutes: 0),
        QuickDuration(label: "4h", hours: 4, minutes: 0),
        QuickDuration(label: "8h", hours: 8, minutes: 0)
    ]
}

/// Shared state for the main window and the menu bar popover.
final class PrintModel: ObservableObject {
    private enum Keys {
        static let hours = "printHours"
        static let minutes = "printMinutes"
    }

    @Published var hours: Int {
        didSet {
            defaults.set(hours, forKey: Keys.hours)
            reanchorIfNeeded()
        }
    }

    @Published var minutes: Int {
        didSet {
            defaults.set(minutes, forKey: Keys.minutes)
            reanchorIfNeeded()
        }
    }

    @Published var startMode: StartMode = .now {
        didSet {
            if startMode == .now {
                anchor = .now
            }
        }
    }

    @Published var anchor = Date.now
    @Published var customStart = Date.now

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hours = defaults.integer(forKey: Keys.hours)
        self.minutes = defaults.integer(forKey: Keys.minutes)
    }

    var start: Date {
        startMode == .now ? anchor : customStart
    }

    var duration: TimeInterval {
        PrintTime.duration(hours: hours, minutes: minutes)
    }

    var hasDuration: Bool {
        duration > 0
    }

    var finish: Date {
        start.addingTimeInterval(duration)
    }

    func setDuration(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }

    func resetToNow() {
        anchor = .now
    }

    func copyFinishTime() {
        let text = finish.formatted(
            .dateTime
                .weekday(.wide)
                .month(.wide)
                .day()
                .year()
                .hour()
                .minute()
        )

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func reanchorIfNeeded() {
        if startMode == .now {
            anchor = .now
        }
    }
}

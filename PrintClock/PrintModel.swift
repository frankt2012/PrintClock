import AppKit
import Combine
import Foundation
import PrintClockKit

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

/// Shared state for the main window, menu bar popover, and Settings.
@MainActor
final class PrintModel: ObservableObject {
    static let notifyWhenFinishedKey = "notifyWhenFinished"

    private enum Keys {
        static let hours = "printHours"
        static let minutes = "printMinutes"
        static let startMode = "printStartMode"
        static let anchor = "printAnchor"
        static let customStart = "printCustomStart"
        static let lastUpdateCheck = "lastUpdateCheck"
        static let iconMode = IconMode.storageKey
    }

    @Published var hours: Int {
        didSet {
            defaults.set(hours, forKey: Keys.hours)
            reanchorIfNeeded()
            scheduleNotification()
        }
    }

    @Published var minutes: Int {
        didSet {
            defaults.set(minutes, forKey: Keys.minutes)
            reanchorIfNeeded()
            scheduleNotification()
        }
    }

    @Published var startMode: StartMode {
        didSet {
            defaults.set(startMode.rawValue, forKey: Keys.startMode)
            if startMode == .now {
                anchor = .now
            }
            scheduleNotification()
        }
    }

    @Published var anchor: Date {
        didSet {
            defaults.set(anchor, forKey: Keys.anchor)
        }
    }

    @Published var customStart: Date {
        didSet {
            defaults.set(customStart, forKey: Keys.customStart)
            scheduleNotification()
        }
    }

    @Published var iconMode: IconMode {
        didSet {
            defaults.set(iconMode.rawValue, forKey: Keys.iconMode)
            applyIconMode()
        }
    }

    @Published private(set) var availableUpdate: AvailableUpdate?
    @Published private(set) var isCheckingForUpdates = false
    @Published private(set) var updateCheckMessage: String?

    private let defaults: UserDefaults
    private var updatePollTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hours = defaults.integer(forKey: Keys.hours)
        self.minutes = defaults.integer(forKey: Keys.minutes)

        let savedMode = StartMode(rawValue: defaults.string(forKey: Keys.startMode) ?? "") ?? .now
        self.startMode = savedMode
        self.anchor = defaults.object(forKey: Keys.anchor) as? Date ?? .now
        self.customStart = defaults.object(forKey: Keys.customStart) as? Date ?? .now
        self.iconMode = IconMode(rawValue: defaults.string(forKey: Keys.iconMode) ?? "") ?? .both

        let savedDuration = PrintTime.duration(hours: hours, minutes: minutes)
        let savedStart = savedMode == .now ? anchor : customStart
        let isActivePrint = savedDuration > 0
            && savedStart.addingTimeInterval(savedDuration) > .now

        if !isActivePrint {
            // Do not carry a finished/stale start into the calculator.
            anchor = .now
            customStart = .now
            defaults.set(anchor, forKey: Keys.anchor)
            defaults.set(customStart, forKey: Keys.customStart)
            defaults.set(hours, forKey: Keys.hours)
            defaults.set(minutes, forKey: Keys.minutes)
            defaults.set(startMode.rawValue, forKey: Keys.startMode)
        }

        NotificationScheduler.configure()

        if isActivePrint {
            scheduleNotification()
        } else {
            NotificationScheduler.cancel()
        }

        startUpdatePolling()

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await self?.checkForUpdates(silent: true)
        }
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

    var notifyWhenFinished: Bool {
        defaults.object(forKey: Self.notifyWhenFinishedKey) as? Bool ?? true
    }

    func setDuration(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }

    func resetToNow() {
        anchor = .now
        scheduleNotification()
    }

    func refreshNotifications() {
        scheduleNotification()
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

    func checkForUpdates(silent: Bool = false) async {
        guard !isCheckingForUpdates else { return }

        isCheckingForUpdates = true
        if !silent {
            updateCheckMessage = nil
        }

        defer {
            isCheckingForUpdates = false
            defaults.set(Date(), forKey: Keys.lastUpdateCheck)
        }

        do {
            if let update = try await UpdateChecker.latestRelease() {
                availableUpdate = update
                updateCheckMessage = nil
            } else {
                availableUpdate = nil
                if !silent {
                    updateCheckMessage = "PrintClock is up to date."
                }
            }
        } catch {
            if !silent {
                updateCheckMessage = "Couldn't check for updates. \(error.localizedDescription)"
            }
        }
    }

    private func reanchorIfNeeded() {
        if startMode == .now {
            anchor = .now
        }
    }

    private func applyIconMode() {
        let policy: NSApplication.ActivationPolicy = iconMode == .menuBarOnly ? .accessory : .regular
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }
    }

    private func scheduleNotification() {
        guard notifyWhenFinished, hasDuration else {
            NotificationScheduler.cancel()
            return
        }

        let finish = self.finish
        NotificationScheduler.schedule(
            finish: finish,
            title: "Print finished",
            body: "Your print should be finished at \(PrintTime.clockText(for: finish))."
        )
    }

    private func startUpdatePolling() {
        updatePollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60 * 60 * 1_000_000_000)

                guard let self else { return }

                let last = self.defaults.object(forKey: Keys.lastUpdateCheck) as? Date ?? .distantPast
                if Date().timeIntervalSince(last) >= 24 * 60 * 60 {
                    await self.checkForUpdates(silent: true)
                }
            }
        }
    }
}

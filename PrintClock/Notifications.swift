import Foundation
import UserNotifications

/// Schedules (and replaces) the single local notification for the current print.
@MainActor
enum NotificationScheduler {
    static let identifier = "print-finished"

    private static var pendingTask: Task<Void, Never>?
    private static let presenter = NotificationPresenter()

    static func configure() {
        UNUserNotificationCenter.current().delegate = presenter
    }

    static func schedule(finish: Date, title: String, body: String) {
        pendingTask?.cancel()

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard finish > .now else {
            return
        }

        let interval = max(1, finish.timeIntervalSinceNow)

        pendingTask = Task {
            var status = await center.notificationSettings().authorizationStatus

            if status == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
                status = await center.notificationSettings().authorizationStatus
            }

            let allowed: [UNAuthorizationStatus] = [.authorized, .provisional]
            guard allowed.contains(status), !Task.isCancelled else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    static func cancel() {
        pendingTask?.cancel()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        var status = await center.notificationSettings().authorizationStatus

        if status == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }

        return status
    }

    /// Sends an immediately visible notification so the user can confirm
    /// notifications work without waiting for a print.
    static func sendTestNotification() {
        Task {
            let status = await requestAuthorization()
            let allowed: [UNAuthorizationStatus] = [.authorized, .provisional]
            guard allowed.contains(status) else { return }

            let content = UNMutableNotificationContent()
            content.title = "PrintClock is ready"
            content.body = "This is what your finished-print notification will look like."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(
                identifier: "print-finished-test",
                content: content,
                trigger: trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}

/// Shows the notification while PrintClock is frontmost too.
private final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

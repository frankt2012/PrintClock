import AppKit
import ServiceManagement
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var model: PrintModel
    @AppStorage(PrintModel.notifyWhenFinishedKey) private var notifyWhenFinished = true

    @State private var launchAtLogin = false
    @State private var loginItemError: String?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if SMAppService.mainApp.status == .requiresApproval {
                    HStack {
                        Text("Approve PrintClock in System Settings → General → Login Items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Login Items") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                        .controlSize(.small)
                    }
                }

                Toggle("Notify when the print finishes", isOn: $notifyWhenFinished)
                    .onChange(of: notifyWhenFinished) { _, enabled in
                        Task {
                            await updateNotificationPreference(enabled)
                        }
                    }

                notificationStatusView
            }

            Section("Updates") {
                LabeledContent("Version", value: currentVersion)

                HStack {
                    Button(model.isCheckingForUpdates ? "Checking…" : "Check for Updates") {
                        Task {
                            await model.checkForUpdates()
                        }
                    }
                    .disabled(model.isCheckingForUpdates)

                    Spacer()

                    if let update = model.availableUpdate {
                        Button("Download \(update.version)") {
                            NSWorkspace.shared.open(update.url)
                        }
                    }
                }

                if let update = model.availableUpdate {
                    Text("Version \(update.version) is available.")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if let message = model.updateCheckMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("PrintClock checks GitHub for updates once a day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 400)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .task {
            notificationStatus = await NotificationScheduler.authorizationStatus()
        }
    }

    @ViewBuilder
    private var notificationStatusView: some View {
        switch notificationStatus {
        case .denied:
            HStack {
                Label("Notifications are disabled in System Settings.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Spacer()
                Button("Open Notification Settings") {
                    openNotificationSettings()
                }
                .controlSize(.small)
            }
        case .notDetermined:
            Text("macOS will ask for notification permission the first time you enter a print time.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .authorized, .provisional:
            HStack {
                Text("You'll get a notification when the print time reaches zero.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Test") {
                    NotificationScheduler.sendTestNotification()
                }
                .controlSize(.small)
            }
        @unknown default:
            EmptyView()
        }
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            launchAtLogin = SMAppService.mainApp.status == .enabled
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func updateNotificationPreference(_ enabled: Bool) async {
        if enabled {
            notificationStatus = await NotificationScheduler.requestAuthorization()
        } else {
            NotificationScheduler.cancel()
            notificationStatus = await NotificationScheduler.authorizationStatus()
        }

        model.refreshNotifications()
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PrintModel())
}

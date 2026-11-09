import SwiftUI

@main
struct PrintClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = PrintModel()

    var body: some Scene {
        WindowGroup("PrintClock", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 470, height: 670)

        MenuBarExtra(isInserted: Binding(
            get: { model.iconMode != .dockOnly },
            set: { inserted in
                if inserted {
                    if model.iconMode == .dockOnly {
                        model.iconMode = .both
                    }
                } else if model.iconMode != .dockOnly {
                    model.iconMode = .dockOnly
                }
            }
        )) {
            MenuBarView()
                .environmentObject(model)
        } label: {
            Image(systemName: "clock.badge.checkmark")
                .accessibilityLabel("PrintClock")
                .help("PrintClock")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}

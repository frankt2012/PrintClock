import SwiftUI

@main
struct PrintClockApp: App {
    @StateObject private var model = PrintModel()

    var body: some Scene {
        WindowGroup("PrintClock", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 470, height: 670)

        MenuBarExtra {
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

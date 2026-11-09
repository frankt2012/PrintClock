import SwiftUI

@main
struct TimeCalculatorApp: App {
    @StateObject private var model = PrintModel()

    var body: some Scene {
        WindowGroup("Time Calculator", id: "main") {
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
                .accessibilityLabel("Time Calculator")
                .help("Time Calculator")
        }
        .menuBarExtraStyle(.window)
    }
}

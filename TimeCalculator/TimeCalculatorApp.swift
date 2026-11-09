import SwiftUI

@main
struct TimeCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 470, height: 670)
    }
}

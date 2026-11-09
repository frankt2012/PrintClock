import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let raw = UserDefaults.standard.string(forKey: IconMode.storageKey)
            ?? IconMode.both.rawValue
        let mode = IconMode(rawValue: raw) ?? .both
        NSApp.setActivationPolicy(mode == .menuBarOnly ? .accessory : .regular)
    }
}

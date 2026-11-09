import Foundation

/// Where the app is reachable from.
enum IconMode: String, CaseIterable, Identifiable {
    case both
    case menuBarOnly
    case dockOnly

    static let storageKey = "iconMode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .both:
            return "Dock and menu bar"
        case .menuBarOnly:
            return "Menu bar only"
        case .dockOnly:
            return "Dock only"
        }
    }
}

import Foundation

/// A newer GitHub release than the running build.
public struct AvailableUpdate: Equatable, Sendable {
    public let version: String
    public let url: URL
    public let notes: String?
    public let downloadURL: URL?
    public let sha256: String?

    public init(
        version: String,
        url: URL,
        notes: String?,
        downloadURL: URL? = nil,
        sha256: String? = nil
    ) {
        self.version = version
        self.url = url
        self.notes = notes
        self.downloadURL = downloadURL
        self.sha256 = sha256
    }
}

/// Checks the project's GitHub releases for a newer version. This is a
/// lightweight replacement for Sparkle: it only tells the user an update
/// exists and links to the release page.
public enum UpdateChecker {
    public static let repository = "frankt2012/PrintClock"

    private struct Asset: Decodable {
        let name: String
        let browser_download_url: String
        let digest: String?
    }

    private struct Release: Decodable {
        let tag_name: String
        let html_url: String
        let body: String?
        let assets: [Asset]?
    }

    public enum CheckError: LocalizedError {
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The update server returned an unexpected response."
            }
        }
    }

    public static func currentVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// Returns a newer release, or nil when this is the latest version.
    public static func latestRelease(allowSame: Bool = false) async throws -> AvailableUpdate? {
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            throw CheckError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("PrintClock/\(currentVersion())", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CheckError.invalidResponse
        }

        // No releases yet: there is nothing newer to offer.
        if http.statusCode == 404 {
            return nil
        }

        guard http.statusCode == 200 else {
            throw CheckError.invalidResponse
        }

        let release = try JSONDecoder().decode(Release.self, from: data)
        guard let releaseURL = URL(string: release.html_url) else {
            throw CheckError.invalidResponse
        }

        let latest = normalise(release.tag_name)
        guard allowSame || isNewer(latest, than: currentVersion()) else {
            return nil
        }

        let dmg = release.assets?.first { $0.name.lowercased().hasSuffix(".dmg") }
        let downloadURL = dmg.flatMap { URL(string: $0.browser_download_url) }
        let sha = dmg?.digest?
            .replacingOccurrences(of: "sha256:", with: "")
            .lowercased()

        return AvailableUpdate(
            version: latest,
            url: releaseURL,
            notes: release.body,
            downloadURL: downloadURL,
            sha256: sha
        )
    }

    public static func normalise(_ version: String) -> String {
        version.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    /// Compares dotted numeric versions. Missing components are treated as 0,
    /// so 1.0 and 1.0.0 are equal, and 1.0.1 is newer than 1.0.
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = normalise(candidate).split(separator: ".").map { Int($0) ?? 0 }
        let b = normalise(current).split(separator: ".").map { Int($0) ?? 0 }
        let count = max(a.count, b.count)

        for index in 0..<count {
            let left = index < a.count ? a[index] : 0
            let right = index < b.count ? b[index] : 0
            if left != right {
                return left > right
            }
        }

        return false
    }
}

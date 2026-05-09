import Foundation
import OSLog

/// Polls Apple's public iTunes Lookup API to detect when a newer version of
/// Untunnel is available on the App Store. No backend required.
///
/// Strategy:
/// - At most one network call per 24h (cache).
/// - If the user dismisses the prompt ("Plus tard"), snooze for 24h before
///   asking again.
/// - All failures (offline, API error, app not yet on Store) silently
///   return `nil` so the user never sees an error toast for a check that
///   was never user-initiated.
///
/// Privacy note: this is currently the only outbound network call in the
/// app. The query sends only the app's own bundle ID + the device region
/// to `itunes.apple.com`. No personal data, no analytics. Worth keeping
/// `Aucune donnée ne quitte cet iPhone` in mind in the about copy.
enum UpdateChecker {
    private static let logger = Logger(subsystem: "rewolf.Tunnel", category: "UpdateChecker")

    struct Outcome: Identifiable, Equatable {
        let latestVersion: String
        let appStoreURL: URL
        var id: String { latestVersion }
    }

    /// Returns an `Outcome` if a newer version is available *and* the user
    /// hasn't been asked recently. Returns `nil` otherwise (no update,
    /// snoozed, cached, or any failure).
    static func checkForAvailableUpdate() async -> Outcome? {
        let now = Date()

        if let snoozeUntil = UserDefaults.standard.object(forKey: StorageKeys.snoozeUntil) as? Date,
           snoozeUntil > now {
            return nil
        }

        if let lastCheck = UserDefaults.standard.object(forKey: StorageKeys.lastCheckAt) as? Date,
           now.timeIntervalSince(lastCheck) < cacheLifetime {
            return nil
        }

        UserDefaults.standard.set(now, forKey: StorageKeys.lastCheckAt)

        guard let url = lookupURL() else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            let payload = try JSONDecoder().decode(LookupPayload.self, from: data)
            guard let result = payload.results.first else {
                logger.notice("App not on the Store for this region — skipping.")
                return nil
            }

            let installed = installedVersion()
            let isNewer = installed.compare(result.version, options: .numeric) == .orderedAscending
            guard isNewer else { return nil }

            guard let appStoreURL = appStoreURL(trackId: result.trackId) else { return nil }
            return Outcome(latestVersion: result.version, appStoreURL: appStoreURL)
        } catch {
            logger.notice("Update check failed silently: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Postpone the prompt for 24h. Called when the user taps "Plus tard".
    static func snooze(for duration: TimeInterval = 24 * 3600) {
        UserDefaults.standard.set(Date().addingTimeInterval(duration), forKey: StorageKeys.snoozeUntil)
    }

    // MARK: - Internals

    private static let cacheLifetime: TimeInterval = 24 * 3600

    private static func installedVersion() -> String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }

    private static func lookupURL() -> URL? {
        let bundleID = Bundle.main.bundleIdentifier ?? "rewolf.Tunnel"
        // Region matters: an app released only in FR returns `resultCount: 0`
        // when queried with `country=US`. Default to FR if the device has no
        // region set (rare).
        let regionCode = Locale.current.region?.identifier ?? "FR"
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: regionCode),
        ]
        return components?.url
    }

    private static func appStoreURL(trackId: Int) -> URL? {
        // `itms-apps://` opens directly in the App Store app without a
        // Safari redirect.
        URL(string: "itms-apps://itunes.apple.com/app/id\(trackId)")
    }

    private struct LookupPayload: Decodable {
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String
        let trackId: Int
    }

    private enum StorageKeys {
        static let lastCheckAt = "app.updateChecker.lastCheckAt"
        static let snoozeUntil = "app.updateChecker.snoozeUntil"
    }
}

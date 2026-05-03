import Foundation
import SweetSpotKit

/// Persists the last-known SessionSnapshot to UserDefaults so the watch can
/// keep counting down even when disconnected from the iPhone.
final class WatchSnapshotCache: @unchecked Sendable {
    static let shared = WatchSnapshotCache()
    private let key = "sweetspot.watch.snapshot"
    private let defaults = UserDefaults(suiteName: AppGroup.identifier)
        ?? .standard

    func read() -> SessionSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SessionSnapshot.self, from: data)
    }

    func write(_ snapshot: SessionSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }
}

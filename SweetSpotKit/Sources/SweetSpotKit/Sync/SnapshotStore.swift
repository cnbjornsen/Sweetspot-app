import Foundation

/// Read/write the shared SessionSnapshot JSON in the App Group container.
/// Cheap, atomic, and avoids opening SwiftData from the widget process.
public struct SnapshotStore: Sendable {
    public init() {}

    public func read() -> SessionSnapshot {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? Self.decoder.decode(SessionSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    @discardableResult
    public func write(_ snapshot: SessionSnapshot) -> Bool {
        guard let url = AppGroup.snapshotURL else { return false }
        do {
            let data = try Self.encoder.encode(snapshot)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public func clear() {
        guard let url = AppGroup.snapshotURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

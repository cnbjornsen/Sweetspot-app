import Foundation

/// Compact, Codable snapshot of the active session shared across processes
/// (app, widget extension, watch). Widgets and Live Activities read this
/// directly from the App Group container instead of opening SwiftData.
public struct SessionSnapshot: Codable, Hashable, Sendable {
    public var sessionID: UUID?
    public var occasionName: String
    public var state: SnapshotState
    public var nextDrinkAt: Date?
    public var drinkCount: Int
    public var waterCount: Int
    public var currentBAC: Double
    public var peakBAC: Double
    public var soberAt: Date?
    public var plannedEndAt: Date?
    public var quote: String?
    public var updatedAt: Date

    public init(sessionID: UUID? = nil,
                occasionName: String = "",
                state: SnapshotState = .idle,
                nextDrinkAt: Date? = nil,
                drinkCount: Int = 0,
                waterCount: Int = 0,
                currentBAC: Double = 0,
                peakBAC: Double = 0,
                soberAt: Date? = nil,
                plannedEndAt: Date? = nil,
                quote: String? = nil,
                updatedAt: Date = .now) {
        self.sessionID = sessionID
        self.occasionName = occasionName
        self.state = state
        self.nextDrinkAt = nextDrinkAt
        self.drinkCount = drinkCount
        self.waterCount = waterCount
        self.currentBAC = currentBAC
        self.peakBAC = peakBAC
        self.soberAt = soberAt
        self.plannedEndAt = plannedEndAt
        self.quote = quote
        self.updatedAt = updatedAt
    }

    public static let empty = SessionSnapshot()
}

public enum SnapshotState: String, Codable, Sendable {
    case idle
    case waiting
    case readyForDrink
    case maintenance
    case coastingHome
    case ended
}

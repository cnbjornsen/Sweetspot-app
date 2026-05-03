import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity attributes for an active Sweet Spot session.
/// Defined in the shared package so both the iOS app (which calls
/// `Activity.request`/`update`) and the widget extension (which renders the
/// `ActivityConfiguration`) reference the same type.
public struct SweetSpotAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable, Sendable {
        public var nextDrinkAt: Date?
        public var drinkCount: Int
        public var waterCount: Int
        public var currentBAC: Double
        public var soberAt: Date?
        public var snapshotState: SnapshotState
        public var quote: String?

        public init(nextDrinkAt: Date? = nil,
                    drinkCount: Int = 0,
                    waterCount: Int = 0,
                    currentBAC: Double = 0,
                    soberAt: Date? = nil,
                    snapshotState: SnapshotState = .waiting,
                    quote: String? = nil) {
            self.nextDrinkAt = nextDrinkAt
            self.drinkCount = drinkCount
            self.waterCount = waterCount
            self.currentBAC = currentBAC
            self.soberAt = soberAt
            self.snapshotState = snapshotState
            self.quote = quote
        }
    }

    public var sessionID: UUID
    public var occasionName: String
    public var startedAt: Date
    public var plannedEndAt: Date

    public init(sessionID: UUID,
                occasionName: String,
                startedAt: Date,
                plannedEndAt: Date) {
        self.sessionID = sessionID
        self.occasionName = occasionName
        self.startedAt = startedAt
        self.plannedEndAt = plannedEndAt
    }
}

public extension SweetSpotAttributes.State {
    init(snapshot: SessionSnapshot) {
        self.init(nextDrinkAt: snapshot.nextDrinkAt,
                  drinkCount: snapshot.drinkCount,
                  waterCount: snapshot.waterCount,
                  currentBAC: snapshot.currentBAC,
                  soberAt: snapshot.soberAt,
                  snapshotState: snapshot.state,
                  quote: snapshot.quote)
    }
}
#endif

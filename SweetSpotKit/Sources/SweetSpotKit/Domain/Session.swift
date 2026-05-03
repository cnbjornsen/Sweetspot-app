import Foundation
import SwiftData

@Model
public final class Session {
    @Attribute(.unique) public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var plannedEndAt: Date
    public var plannedPeakAt: Date?
    /// JSON-encoded `SessionMode`.
    public var modeData: Data
    public var occasion: Occasion?

    @Relationship(deleteRule: .cascade, inverse: \DrinkEvent.session)
    public var drinks: [DrinkEvent] = []

    // Outcome stats — populated when the session ends.
    public var peakBAC: Double = 0
    public var minutesInSweetSpot: Int = 0
    public var unscheduledExtrasCount: Int = 0
    public var waterCount: Int = 0
    public var soberAt: Date?
    public var endReasonRaw: String?
    public var autoEnded: Bool = false

    public init(id: UUID = UUID(),
                startedAt: Date,
                plannedEndAt: Date,
                plannedPeakAt: Date? = nil,
                mode: SessionMode,
                occasion: Occasion? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.plannedEndAt = plannedEndAt
        self.plannedPeakAt = plannedPeakAt
        self.modeData = (try? JSONEncoder().encode(mode)) ?? Data()
        self.occasion = occasion
    }

    public var mode: SessionMode? {
        try? JSONDecoder().decode(SessionMode.self, from: modeData)
    }

    public func updateMode(_ newMode: SessionMode) {
        modeData = (try? JSONEncoder().encode(newMode)) ?? modeData
        plannedEndAt = newMode.end
        plannedPeakAt = newMode.peak
    }

    public var isActive: Bool { endedAt == nil }

    public var endReason: EndReason? {
        get { endReasonRaw.flatMap(EndReason.init(rawValue:)) }
        set { endReasonRaw = newValue?.rawValue }
    }
}

public enum EndReason: String, Codable, Sendable {
    case user
    case auto
    case crash
}

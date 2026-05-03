import Foundation
import SwiftData

@Model
public final class DrinkEvent {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var typeRaw: String
    /// Ethanol grams snapshotted at log time (after applying any size override).
    public var ethanolGrams: Double
    public var sizeMultiplier: Double
    public var wasScheduled: Bool
    public var notes: String?
    public var session: Session?

    public init(id: UUID = UUID(),
                timestamp: Date,
                type: DrinkType,
                ethanolGrams: Double,
                sizeMultiplier: Double = 1.0,
                wasScheduled: Bool,
                notes: String? = nil,
                session: Session? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.ethanolGrams = ethanolGrams
        self.sizeMultiplier = sizeMultiplier
        self.wasScheduled = wasScheduled
        self.notes = notes
        self.session = session
    }

    public var type: DrinkType {
        get { DrinkType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    /// Pure-value snapshot fed into the BAC engine.
    public var asDrink: Drink {
        Drink(id: id,
              timestamp: timestamp,
              ethanolGrams: ethanolGrams,
              wasScheduled: wasScheduled)
    }
}

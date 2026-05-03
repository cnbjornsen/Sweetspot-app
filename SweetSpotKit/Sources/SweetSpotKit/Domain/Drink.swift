import Foundation

/// Pure value snapshot of a logged drink, fed into the BAC engine.
/// The `@Model DrinkEvent` produces one of these via `var drink: Drink`.
public struct Drink: Hashable, Codable, Sendable, Identifiable {
    public var id: UUID
    public var timestamp: Date
    /// Ethanol grams snapshotted at log time (after applying any size override).
    public var ethanolGrams: Double
    public var wasScheduled: Bool

    public init(id: UUID = UUID(),
                timestamp: Date,
                ethanolGrams: Double,
                wasScheduled: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.ethanolGrams = ethanolGrams
        self.wasScheduled = wasScheduled
    }

    public var contributesToBAC: Bool { ethanolGrams > 0 }
}

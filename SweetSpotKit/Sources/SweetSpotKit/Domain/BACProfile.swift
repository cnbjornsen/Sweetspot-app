import Foundation

/// Pure value snapshot of the user's profile that drives the BAC math.
/// Decouples the engine from SwiftData. The `@Model UserProfile` produces one
/// of these via `var bacProfile: BACProfile`.
public struct BACProfile: Hashable, Codable, Sendable {
    public var weightKg: Double
    public var sex: BiologicalSex
    /// Grams of pure ethanol in one "standard drink" — locale dependent
    /// (US 14, UK 8, AU/EU 10).
    public var standardDrinkGrams: Double

    public init(weightKg: Double, sex: BiologicalSex, standardDrinkGrams: Double) {
        self.weightKg = weightKg
        self.sex = sex
        self.standardDrinkGrams = standardDrinkGrams
    }

    public var widmarkR: Double { sex.widmarkR }
}

import Foundation

public struct DrinkSizeOverride: Hashable, Codable, Sendable {
    /// 1.0 = normal pour, 2.0 = double, 0.5 = half, etc.
    public var multiplier: Double
    /// Required when the drink is `.custom`; ethanol grams before multiplier.
    public var customEthanolGrams: Double?

    public init(multiplier: Double = 1.0, customEthanolGrams: Double? = nil) {
        self.multiplier = multiplier
        self.customEthanolGrams = customEthanolGrams
    }

    public static let standard = DrinkSizeOverride()
}

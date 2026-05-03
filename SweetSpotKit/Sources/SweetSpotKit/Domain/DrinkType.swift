import Foundation

public enum DrinkType: String, Codable, CaseIterable, Sendable {
    case beer12oz          // 12 oz beer @ 5%   ≈ 14g ethanol (1 US std drink)
    case wine5oz           // 5 oz wine @ 12%   ≈ 14g ethanol
    case shot15oz          // 1.5 oz spirit @ 40% ≈ 14g ethanol
    case cocktailStandard  // assume 1 std drink
    case custom            // user-supplied ethanol grams via override
    case water             // not alcoholic; logged for pacing

    public var displayName: String {
        switch self {
        case .beer12oz:         return "Beer"
        case .wine5oz:          return "Wine"
        case .shot15oz:         return "Shot"
        case .cocktailStandard: return "Cocktail"
        case .custom:           return "Custom"
        case .water:            return "Water"
        }
    }

    public var emoji: String {
        switch self {
        case .beer12oz:         return "🍺"
        case .wine5oz:          return "🍷"
        case .shot15oz:         return "🥃"
        case .cocktailStandard: return "🍸"
        case .custom:           return "🍹"
        case .water:            return "💧"
        }
    }

    public var contributesToBAC: Bool { self != .water }

    /// Base count of "standard drinks" before any size override.
    public var baseStandardDrinks: Double {
        switch self {
        case .beer12oz, .wine5oz, .shot15oz, .cocktailStandard:
            return 1.0
        case .custom, .water:
            return 0.0
        }
    }

    /// Ethanol grams contributed for this user, given an optional size override.
    /// `.water` always returns 0. `.custom` requires `override.customEthanolGrams`.
    public func ethanolGrams(profile: BACProfile,
                             override: DrinkSizeOverride = .standard) -> Double {
        switch self {
        case .water:
            return 0
        case .custom:
            return (override.customEthanolGrams ?? 0) * override.multiplier
        case .beer12oz, .wine5oz, .shot15oz, .cocktailStandard:
            return baseStandardDrinks * profile.standardDrinkGrams * override.multiplier
        }
    }
}

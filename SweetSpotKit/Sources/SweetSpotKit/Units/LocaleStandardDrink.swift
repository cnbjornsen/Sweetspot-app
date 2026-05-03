import Foundation

/// Resolves the default ethanol grams per "standard drink" for a given locale.
/// Users can override in Settings; this only seeds the default.
public enum LocaleStandardDrink {
    /// Grams of pure ethanol in one standard drink, per region's official
    /// public-health definition. Falls back to 14 g (US) when unknown.
    public static func grams(for locale: Locale = .current) -> Double {
        guard let region = locale.region?.identifier.uppercased() else {
            return 14.0
        }
        switch region {
        case "GB", "IE":                                    return 8.0
        case "AU", "NZ":                                    return 10.0
        case "AT", "BE", "CZ", "DE", "DK", "ES", "FI",
             "FR", "GR", "HU", "IS", "IT", "LU", "NL",
             "NO", "PL", "PT", "SE", "SI", "SK", "CH":     return 10.0
        case "JP":                                          return 20.0
        case "CA":                                          return 13.6
        case "US", "MX":                                    return 14.0
        default:                                            return 14.0
        }
    }

    /// Whole-number candidates surfaced in Settings ("How big is one drink?").
    public static let presets: [Double] = [8, 10, 12, 13.6, 14, 16, 20]
}

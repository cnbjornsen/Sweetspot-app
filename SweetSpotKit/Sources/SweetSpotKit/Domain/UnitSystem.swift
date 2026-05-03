import Foundation

public enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric
    case imperial

    public static func defaultForCurrentLocale() -> UnitSystem {
        Locale.current.measurementSystem == .metric ? .metric : .imperial
    }
}

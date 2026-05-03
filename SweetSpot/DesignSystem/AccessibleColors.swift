import SwiftUI

/// Color-blind-aware BAC zone palette. Each zone also carries a redundant
/// SF Symbol so users with color vision differences get a non-color cue.
enum BACZone: Sendable {
    case sober          // 0.000 – 0.005
    case sweetSpot      // 0.005 – 0.050
    case overshoot      // 0.050 – 0.080
    case dangerous      // > 0.080

    static func zone(for bac: Double) -> BACZone {
        switch bac {
        case ..<0.005:    return .sober
        case ..<0.05:     return .sweetSpot
        case ..<0.08:     return .overshoot
        default:          return .dangerous
        }
    }

    var color: Color {
        switch self {
        case .sober:      return Color(red: 0.55, green: 0.65, blue: 0.95)
        case .sweetSpot:  return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .overshoot:  return Color(red: 0.98, green: 0.75, blue: 0.20)
        case .dangerous:  return Color(red: 0.95, green: 0.35, blue: 0.40)
        }
    }

    /// SF Symbol used as the redundant non-color cue.
    var symbolName: String {
        switch self {
        case .sober:      return "moon.zzz.fill"
        case .sweetSpot:  return "checkmark.seal.fill"
        case .overshoot:  return "exclamationmark.triangle.fill"
        case .dangerous:  return "xmark.octagon.fill"
        }
    }

    var label: String {
        switch self {
        case .sober:      return "Sober"
        case .sweetSpot:  return "Sweet spot"
        case .overshoot:  return "Above sweet spot"
        case .dangerous:  return "Risk zone — slow down"
        }
    }
}

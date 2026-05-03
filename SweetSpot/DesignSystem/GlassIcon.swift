import SwiftUI
import SweetSpotKit

/// Map a `DrinkType` to an SF Symbol so the icons stay sharp at any size and
/// pick up Dynamic Type / accessibility tints automatically.
extension DrinkType {
    var sfSymbolName: String {
        switch self {
        case .beer12oz:         return "mug.fill"
        case .wine5oz:          return "wineglass.fill"
        case .shot15oz:         return "drop.fill"
        case .cocktailStandard: return "wineglass"
        case .custom:           return "sparkles"
        case .water:            return "drop"
        }
    }
}

struct GlassIcon: View {
    let type: DrinkType
    var body: some View {
        Image(systemName: type.sfSymbolName)
            .symbolRenderingMode(.hierarchical)
    }
}

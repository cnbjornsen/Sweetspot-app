import Foundation

public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male
    case female

    public var widmarkR: Double {
        switch self {
        case .male:   return 0.68
        case .female: return 0.55
        }
    }
}

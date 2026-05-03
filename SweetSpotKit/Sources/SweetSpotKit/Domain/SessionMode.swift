import Foundation

public enum SessionMode: Codable, Hashable, Sendable {
    /// Spread drinks evenly across the session window.
    case evenlyPaced(start: Date, end: Date)
    /// Ramp drinks up to a target peak BAC at `peak`, then maintenance-pace
    /// (≈ 1 std drink/hr equivalent) through `end`.
    case peakThenMaintain(start: Date, peak: Date, end: Date)

    public var start: Date {
        switch self {
        case .evenlyPaced(let s, _):       return s
        case .peakThenMaintain(let s, _, _): return s
        }
    }

    public var end: Date {
        switch self {
        case .evenlyPaced(_, let e):       return e
        case .peakThenMaintain(_, _, let e): return e
        }
    }

    public var peak: Date? {
        switch self {
        case .evenlyPaced:                 return nil
        case .peakThenMaintain(_, let p, _): return p
        }
    }
}

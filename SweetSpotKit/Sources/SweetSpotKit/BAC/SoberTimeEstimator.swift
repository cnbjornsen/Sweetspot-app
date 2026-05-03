import Foundation

/// Estimates when the user's BAC will fall below given thresholds.
/// Always disclaim: this is an estimate, not legal/medical advice.
public struct SoberTimeEstimator: Sendable {
    public let timeline: BACTimeline

    public init(timeline: BACTimeline) {
        self.timeline = timeline
    }

    /// Predicted time the user reaches BAC ≤ `threshold` after `referenceDate`.
    /// Returns `referenceDate` itself if already below.
    public func time(reaching threshold: Double,
                     after referenceDate: Date) -> Date? {
        if timeline.bac(at: referenceDate) <= threshold { return referenceDate }
        return timeline.crossesDown(to: threshold, after: referenceDate)
    }

    /// Common thresholds in one call.
    public func estimates(after referenceDate: Date) -> Estimates {
        Estimates(
            sober: time(reaching: 0.0, after: referenceDate),
            belowDriving0_05: time(reaching: 0.05, after: referenceDate),
            belowDriving0_08: time(reaching: 0.08, after: referenceDate),
            belowProfessional0_02: time(reaching: 0.02, after: referenceDate)
        )
    }

    public struct Estimates: Hashable, Sendable {
        public var sober: Date?
        public var belowDriving0_05: Date?
        public var belowDriving0_08: Date?
        public var belowProfessional0_02: Date?
    }
}

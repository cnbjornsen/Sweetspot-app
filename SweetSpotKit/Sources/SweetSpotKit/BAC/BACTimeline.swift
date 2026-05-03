import Foundation

/// BAC over time given a list of drinks and a profile. Stateless — recompute
/// freely; cheap (linear in drinks for each query).
public struct BACTimeline: Sendable {
    public let drinks: [Drink]
    public let profile: BACProfile
    public let beta: Double

    public init(drinks: [Drink],
                profile: BACProfile,
                beta: Double = WidmarkCalculator.defaultBeta) {
        self.drinks = drinks
            .filter(\.contributesToBAC)
            .sorted { $0.timestamp < $1.timestamp }
        self.profile = profile
        self.beta = beta
    }

    /// %BAC at moment `t`. Drinks in the future contribute nothing.
    public func bac(at t: Date) -> Double {
        var total = 0.0
        for drink in drinks {
            guard drink.timestamp <= t else { continue }
            let hours = t.timeIntervalSince(drink.timestamp) / 3600.0
            total += WidmarkCalculator.bac(
                ethanolGrams: drink.ethanolGrams,
                weightKg: profile.weightKg,
                r: profile.widmarkR,
                hoursElapsed: hours,
                beta: beta
            )
        }
        return total
    }

    /// %BAC if a hypothetical extra drink of `extraGrams` were logged at `t`.
    /// Used by the planner to evaluate candidate schedules without mutating.
    public func bacIfAdded(extraGrams: Double, at addedAt: Date, evaluatedAt t: Date) -> Double {
        var total = bac(at: t)
        if addedAt <= t {
            let hours = t.timeIntervalSince(addedAt) / 3600.0
            total += WidmarkCalculator.bac(
                ethanolGrams: extraGrams,
                weightKg: profile.weightKg,
                r: profile.widmarkR,
                hoursElapsed: hours,
                beta: beta
            )
        }
        return total
    }

    /// Peak BAC sampled across `range` at `step` (default 1 minute).
    public func peakBAC(in range: ClosedRange<Date>,
                        step: TimeInterval = 60) -> Double {
        var peak = 0.0
        var t = range.lowerBound
        while t <= range.upperBound {
            peak = max(peak, bac(at: t))
            t = t.addingTimeInterval(step)
        }
        return peak
    }

    /// Minutes within `range` where BAC ≤ `threshold`.
    public func minutesAtOrBelow(_ threshold: Double,
                                 in range: ClosedRange<Date>,
                                 step: TimeInterval = 60) -> Int {
        var minutes = 0
        var t = range.lowerBound
        while t <= range.upperBound {
            if bac(at: t) <= threshold { minutes += 1 }
            t = t.addingTimeInterval(step)
        }
        return minutes
    }

    /// Earliest time on/after `start` where BAC reaches `target` (going down).
    /// Returns `nil` if BAC never reaches `target` within `searchHorizon`.
    public func crossesDown(to target: Double,
                            after start: Date,
                            searchHorizon: TimeInterval = 24 * 3600,
                            step: TimeInterval = 60) -> Date? {
        var t = start
        let end = start.addingTimeInterval(searchHorizon)
        while t <= end {
            if bac(at: t) <= target { return t }
            t = t.addingTimeInterval(step)
        }
        return nil
    }
}

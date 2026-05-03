import Foundation

public struct ScheduledDrink: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let scheduledAt: Date
    /// Standard drinks the planner intends at this slot (typically 1.0).
    public let standardDrinks: Double

    public init(id: UUID = UUID(), scheduledAt: Date, standardDrinks: Double) {
        self.id = id
        self.scheduledAt = scheduledAt
        self.standardDrinks = standardDrinks
    }
}

public struct PlannerInput: Sendable {
    public var profile: BACProfile
    public var mode: SessionMode
    public var now: Date
    public var alreadyConsumed: [Drink]
    public var target: Double
    public var epsilon: Double
    public var beta: Double

    public init(profile: BACProfile,
                mode: SessionMode,
                now: Date,
                alreadyConsumed: [Drink],
                target: Double = 0.05,
                epsilon: Double = 0.001,
                beta: Double = WidmarkCalculator.defaultBeta) {
        self.profile = profile
        self.mode = mode
        self.now = now
        self.alreadyConsumed = alreadyConsumed
        self.target = target
        self.epsilon = epsilon
        self.beta = beta
    }
}

/// Produces an ordered schedule of drinks that aims to keep BAC ≤ `target`.
/// Pure: same input → same output. Recompute on every state change.
public struct DrinkPlanner: Sendable {

    public init() {}

    public func schedule(_ input: PlannerInput) -> [ScheduledDrink] {
        switch input.mode {
        case let .evenlyPaced(start, end):
            return scheduleEvenlyPaced(input: input, start: start, end: end)
        case let .peakThenMaintain(start, peak, end):
            return schedulePeakThenMaintain(input: input,
                                            start: start,
                                            peak: peak,
                                            end: end)
        }
    }

    // MARK: Mode A — evenly paced

    private func scheduleEvenlyPaced(input: PlannerInput,
                                     start: Date,
                                     end: Date) -> [ScheduledDrink] {
        guard end > start else { return [] }

        let standardGrams = input.profile.standardDrinkGrams
        let timeline = BACTimeline(drinks: input.alreadyConsumed,
                                   profile: input.profile,
                                   beta: input.beta)

        // Push the first slot to "now or later, when adding a drink is safe."
        let effectiveStart = max(input.now, start)
        guard effectiveStart < end else {
            return maintenanceTail(input: input,
                                   from: effectiveStart,
                                   to: end,
                                   timeline: timeline)
        }

        guard let firstSlot = nextSafeSlot(input: input,
                                           after: effectiveStart,
                                           extraGrams: standardGrams,
                                           timeline: timeline),
              firstSlot < end
        else { return [] }

        // Bisect on the *actual* placement window so the safety check
        // matches what we'll schedule.
        let maxN = upperBoundForN(input: input, start: firstSlot, end: end)
        let chosen = bisectMaxN(low: 0,
                                high: maxN,
                                input: input,
                                start: firstSlot,
                                end: end,
                                timeline: timeline)

        guard chosen > 0 else {
            return maintenanceTail(input: input,
                                   from: firstSlot,
                                   to: end,
                                   timeline: timeline)
        }

        let window = end.timeIntervalSince(firstSlot)
        let spacing: TimeInterval = chosen == 1 ? 0 : window / Double(chosen)
        var schedule: [ScheduledDrink] = []
        for i in 0..<chosen {
            let at = firstSlot.addingTimeInterval(spacing * Double(i))
            schedule.append(ScheduledDrink(scheduledAt: at, standardDrinks: 1.0))
        }
        return schedule
    }

    // MARK: Mode B — ramp to peak, then maintain

    private func schedulePeakThenMaintain(input: PlannerInput,
                                          start: Date,
                                          peak: Date,
                                          end: Date) -> [ScheduledDrink] {
        guard peak > start, end >= peak else { return [] }

        let standardGrams = input.profile.standardDrinkGrams
        let timeline = BACTimeline(drinks: input.alreadyConsumed,
                                   profile: input.profile,
                                   beta: input.beta)
        let effectiveStart = max(input.now, start)
        var schedule: [ScheduledDrink] = []

        if effectiveStart < peak,
           let firstSlot = nextSafeSlot(input: input,
                                        after: effectiveStart,
                                        extraGrams: standardGrams,
                                        timeline: timeline) {
            if firstSlot < peak {
                // Bisect on actual placement window so safety holds.
                let rampMax = upperBoundForN(input: input,
                                             start: firstSlot,
                                             end: peak)
                let ramp = bisectMaxN(low: 0,
                                      high: rampMax,
                                      input: input,
                                      start: firstSlot,
                                      end: peak,
                                      timeline: timeline)
                if ramp > 0 {
                    let window = peak.timeIntervalSince(firstSlot)
                    let spacing: TimeInterval = ramp == 1
                        ? 0
                        : window / Double(ramp)
                    for i in 0..<ramp {
                        let at = firstSlot.addingTimeInterval(spacing * Double(i))
                        schedule.append(ScheduledDrink(scheduledAt: at,
                                                       standardDrinks: 1.0))
                    }
                }
            }
        }

        // Maintenance: after the last ramp slot (or `peak`, whichever later),
        // pace at one std-drink-equivalent per hour-of-elimination.
        let lastRampAt = schedule.last?.scheduledAt ?? peak
        let maintenanceStart = max(lastRampAt, peak)
        let tail = maintenanceTail(input: input,
                                   from: maintenanceStart,
                                   to: end,
                                   timeline: timeline)
        schedule.append(contentsOf: tail)

        return schedule
    }

    // MARK: Helpers

    /// Maintenance pace: place a std drink every `1 / (β · r · weight_kg · 10)` hours.
    /// That's the rate at which the body eliminates one std drink's worth of ethanol.
    private func maintenanceTail(input: PlannerInput,
                                 from start: Date,
                                 to end: Date,
                                 timeline: BACTimeline) -> [ScheduledDrink] {
        guard end > start else { return [] }
        let standardGrams = input.profile.standardDrinkGrams
        // Hours to eliminate one std drink's BAC contribution:
        //   ΔBAC_oneDrink = (standardGrams / (r · weightKg · 1000)) · 100
        //   hours_per_drink = ΔBAC_oneDrink / β
        let deltaPerDrink = (standardGrams /
                             (input.profile.widmarkR * input.profile.weightKg * 1000.0)) * 100.0
        let hoursPerDrink = deltaPerDrink / input.beta
        let spacing = max(900.0, hoursPerDrink * 3600.0) // floor at 15 min
        guard var t = nextSafeSlot(input: input,
                                   after: start,
                                   extraGrams: standardGrams,
                                   timeline: timeline) else { return [] }
        var schedule: [ScheduledDrink] = []
        while t <= end {
            schedule.append(ScheduledDrink(scheduledAt: t, standardDrinks: 1.0))
            t = t.addingTimeInterval(spacing)
        }
        return schedule
    }

    /// Push the candidate forward until adding one std drink at `t` would
    /// keep BAC ≤ target − ε. Returns nil if no safe slot exists within
    /// 12 hours of `start` — caller should produce an empty schedule.
    private func nextSafeSlot(input: PlannerInput,
                              after start: Date,
                              extraGrams: Double,
                              timeline: BACTimeline) -> Date? {
        let safeTarget = input.target - input.epsilon
        var t = start
        let cap = start.addingTimeInterval(12 * 3600)
        while t <= cap {
            let projected = timeline.bacIfAdded(extraGrams: extraGrams,
                                                at: t,
                                                evaluatedAt: t)
            if projected <= safeTarget { return t }
            t = t.addingTimeInterval(60)
        }
        return nil
    }

    /// A loose (intentionally over-generous) upper bound on N for the bisection.
    /// The "all drinks bunched" formula `(target + β·T) / Δ` underestimates what
    /// evenly-spaced drinks can sustain because elimination between sips makes
    /// room for more — empirically by a factor of ~5 for typical inputs. We
    /// scale by 6× and floor at 12 to be safe.
    private func upperBoundForN(input: PlannerInput,
                                start: Date,
                                end: Date) -> Int {
        let deltaPerDrink = (input.profile.standardDrinkGrams /
                             (input.profile.widmarkR * input.profile.weightKg * 1000.0)) * 100.0
        guard deltaPerDrink > 0 else { return 0 }
        let durationHours = max(0, end.timeIntervalSince(start) / 3600.0)
        let bunchedCap = (input.target + input.beta * durationHours) / deltaPerDrink
        return max(12, Int((bunchedCap * 6).rounded(.up)))
    }

    /// Largest N such that an evenly-spaced N-drink schedule across [start, end]
    /// keeps the running BAC ≤ target at all sample points.
    private func bisectMaxN(low: Int,
                            high: Int,
                            input: PlannerInput,
                            start: Date,
                            end: Date,
                            timeline: BACTimeline) -> Int {
        var lo = low
        var hi = high
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if isSafeSchedule(n: mid,
                              input: input,
                              start: start,
                              end: end,
                              timeline: timeline) {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }

    /// Simulate `n` evenly-spaced std drinks across [start, end] and check
    /// that BAC stays ≤ target at every sample (1-minute granularity).
    private func isSafeSchedule(n: Int,
                                input: PlannerInput,
                                start: Date,
                                end: Date,
                                timeline: BACTimeline) -> Bool {
        guard n > 0 else { return true }
        let standardGrams = input.profile.standardDrinkGrams
        let window = end.timeIntervalSince(start)
        guard window > 0 else { return false }
        let spacing: TimeInterval = n == 1 ? 0 : window / Double(n)

        // Build a hypothetical drink list = already consumed + n new slots.
        var hypothetical = input.alreadyConsumed.filter(\.contributesToBAC)
        for i in 0..<n {
            let at = start.addingTimeInterval(spacing * Double(i))
            hypothetical.append(Drink(timestamp: at,
                                      ethanolGrams: standardGrams,
                                      wasScheduled: true))
        }
        let candidate = BACTimeline(drinks: hypothetical,
                                    profile: input.profile,
                                    beta: input.beta)
        let safeTarget = input.target + input.epsilon
        var t = start
        while t <= end {
            if candidate.bac(at: t) > safeTarget { return false }
            t = t.addingTimeInterval(60)
        }
        return true
    }
}

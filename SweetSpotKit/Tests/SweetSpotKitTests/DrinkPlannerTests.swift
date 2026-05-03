import XCTest
@testable import SweetSpotKit

final class DrinkPlannerTests: XCTestCase {

    private let planner = DrinkPlanner()
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    private func profile(weightKg: Double = 70,
                         sex: BiologicalSex = .male,
                         std: Double = 14) -> BACProfile {
        BACProfile(weightKg: weightKg, sex: sex, standardDrinkGrams: std)
    }

    private func runMaxBACCheck(schedule: [ScheduledDrink],
                                profile: BACProfile,
                                start: Date,
                                end: Date,
                                target: Double = 0.05,
                                tolerance: Double = 0.002) -> Double {
        let drinks = schedule.map {
            Drink(timestamp: $0.scheduledAt,
                  ethanolGrams: profile.standardDrinkGrams * $0.standardDrinks,
                  wasScheduled: true)
        }
        let timeline = BACTimeline(drinks: drinks, profile: profile)
        return timeline.peakBAC(in: start...end)
    }

    // MARK: Mode A

    func testModeAProducesNonEmptyForReasonableWindow() {
        let start = now
        let end = start.addingTimeInterval(4 * 3600)
        let input = PlannerInput(profile: profile(),
                                 mode: .evenlyPaced(start: start, end: end),
                                 now: start,
                                 alreadyConsumed: [])
        let schedule = planner.schedule(input)
        XCTAssertFalse(schedule.isEmpty, "4-hour window should plan drinks")
    }

    /// Safety invariant: the produced schedule must never push BAC > 0.05 + ε.
    func testModeASafetyAcrossWeights() {
        let start = now
        let end = start.addingTimeInterval(4 * 3600)
        let weights: [Double] = [50, 60, 70, 85, 100, 130]
        for w in weights {
            let p = profile(weightKg: w)
            let input = PlannerInput(profile: p,
                                     mode: .evenlyPaced(start: start, end: end),
                                     now: start,
                                     alreadyConsumed: [])
            let schedule = planner.schedule(input)
            let peak = runMaxBACCheck(schedule: schedule,
                                      profile: p,
                                      start: start,
                                      end: end)
            XCTAssertLessThanOrEqual(peak, 0.052,
                "Weight \(w) kg produced peak \(peak)")
        }
    }

    func testModeAFemaleSafety() {
        let start = now
        let end = start.addingTimeInterval(3 * 3600)
        let p = profile(weightKg: 60, sex: .female)
        let input = PlannerInput(profile: p,
                                 mode: .evenlyPaced(start: start, end: end),
                                 now: start,
                                 alreadyConsumed: [])
        let schedule = planner.schedule(input)
        let peak = runMaxBACCheck(schedule: schedule,
                                  profile: p,
                                  start: start,
                                  end: end)
        XCTAssertLessThanOrEqual(peak, 0.052)
    }

    func testReplanWhenAlreadyOver() {
        // User chugged 4 drinks before the planner runs.
        let start = now
        let end = start.addingTimeInterval(3 * 3600)
        let p = profile()
        let already = (0..<4).map {
            Drink(timestamp: start.addingTimeInterval(Double($0) * 60),
                  ethanolGrams: 14,
                  wasScheduled: false)
        }
        let input = PlannerInput(profile: p,
                                 mode: .evenlyPaced(start: start, end: end),
                                 now: start.addingTimeInterval(5 * 60),
                                 alreadyConsumed: already)
        let schedule = planner.schedule(input)
        // Either no further drinks scheduled, or the next is far enough out that
        // it's safe at that moment.
        if let next = schedule.first {
            let timeline = BACTimeline(drinks: already, profile: p)
            let projected = timeline.bacIfAdded(extraGrams: 14,
                                                at: next.scheduledAt,
                                                evaluatedAt: next.scheduledAt)
            XCTAssertLessThanOrEqual(projected, 0.052)
        }
    }

    // MARK: Mode B

    func testModeBRampsToPeakThenMaintains() {
        let start = now
        let peak = start.addingTimeInterval(2 * 3600)
        let end = start.addingTimeInterval(5 * 3600)
        let p = profile()
        let input = PlannerInput(profile: p,
                                 mode: .peakThenMaintain(start: start,
                                                         peak: peak,
                                                         end: end),
                                 now: start,
                                 alreadyConsumed: [])
        let schedule = planner.schedule(input)
        XCTAssertFalse(schedule.isEmpty)

        let rampSlots = schedule.filter { $0.scheduledAt < peak }
        let maintenanceSlots = schedule.filter { $0.scheduledAt >= peak }
        XCTAssertGreaterThan(rampSlots.count, 0, "Should ramp up")
        XCTAssertGreaterThanOrEqual(maintenanceSlots.count, 1, "Should maintain after peak")

        let observed = runMaxBACCheck(schedule: schedule,
                                      profile: p,
                                      start: start,
                                      end: end)
        XCTAssertLessThanOrEqual(observed, 0.055)
    }

    // MARK: Property test (smaller — XCTest doesn't have built-in randomness)

    func testRandomizedSafetyInvariant() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<25 {
            let weight = Double.random(in: 50...130, using: &generator)
            let sex: BiologicalSex = Bool.random(using: &generator) ? .male : .female
            let std = [10.0, 14.0].randomElement(using: &generator)!
            let durationHours = Double.random(in: 1...6, using: &generator)
            let start = now
            let end = start.addingTimeInterval(durationHours * 3600)
            let p = profile(weightKg: weight, sex: sex, std: std)
            let mode: SessionMode = Bool.random(using: &generator)
                ? .evenlyPaced(start: start, end: end)
                : .peakThenMaintain(start: start,
                                    peak: start.addingTimeInterval(durationHours * 0.4 * 3600),
                                    end: end)
            let input = PlannerInput(profile: p,
                                     mode: mode,
                                     now: start,
                                     alreadyConsumed: [])
            let schedule = planner.schedule(input)
            let peak = runMaxBACCheck(schedule: schedule,
                                      profile: p,
                                      start: start,
                                      end: end)
            XCTAssertLessThanOrEqual(peak, 0.06,
                "Failed: weight=\(weight) sex=\(sex) std=\(std) hrs=\(durationHours) peak=\(peak)")
        }
    }
}

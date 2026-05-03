import XCTest
@testable import SweetSpotKit

final class BACTimelineTests: XCTestCase {

    private let profile = BACProfile(weightKg: 70, sex: .male, standardDrinkGrams: 14)
    private let now = Date(timeIntervalSinceReferenceDate: 0)

    func testEmptyTimelineIsZero() {
        let t = BACTimeline(drinks: [], profile: profile)
        XCTAssertEqual(t.bac(at: now), 0)
    }

    func testFutureDrinkDoesNotContribute() {
        let future = now.addingTimeInterval(3600)
        let drink = Drink(timestamp: future, ethanolGrams: 14, wasScheduled: true)
        let t = BACTimeline(drinks: [drink], profile: profile)
        XCTAssertEqual(t.bac(at: now), 0)
    }

    func testTwoDrinksAccumulateThenEliminate() {
        let d1 = Drink(timestamp: now, ethanolGrams: 14, wasScheduled: true)
        let d2 = Drink(timestamp: now.addingTimeInterval(1800),
                       ethanolGrams: 14, wasScheduled: true)
        let timeline = BACTimeline(drinks: [d1, d2], profile: profile)

        // At t = 30 min: only d1 has elapsed 0.5 h, d2 just landed.
        let halfHour = now.addingTimeInterval(1800)
        let v = timeline.bac(at: halfHour)
        // d1: 0.02941 - 0.0075 = 0.02191
        // d2: 0.02941 - 0      = 0.02941
        // sum ≈ 0.05132
        XCTAssertEqual(v, 0.05132, accuracy: 0.001)

        // After 10 hours both drinks fully eliminated.
        let later = now.addingTimeInterval(10 * 3600)
        XCTAssertEqual(timeline.bac(at: later), 0, accuracy: 0.001)
    }

    func testWaterDrinkIgnored() {
        let alcohol = Drink(timestamp: now, ethanolGrams: 14, wasScheduled: true)
        let water = Drink(timestamp: now, ethanolGrams: 0, wasScheduled: false)
        let t = BACTimeline(drinks: [alcohol, water], profile: profile)
        XCTAssertEqual(t.bac(at: now), 0.02941, accuracy: 0.0005)
    }

    func testCrossesDownReturnsTimeAtTarget() {
        // 4 std drinks at t=0 → 0.1176%, decays at 0.015/hr → reaches 0.05 around 4.5 h.
        let drink = Drink(timestamp: now, ethanolGrams: 56, wasScheduled: true)
        let timeline = BACTimeline(drinks: [drink], profile: profile)
        let crossing = timeline.crossesDown(to: 0.05, after: now)
        XCTAssertNotNil(crossing)
        if let crossing {
            let hours = crossing.timeIntervalSince(now) / 3600
            XCTAssertEqual(hours, 4.5, accuracy: 0.1)
        }
    }
}

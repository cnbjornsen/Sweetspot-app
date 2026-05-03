import XCTest
@testable import SweetSpotKit

final class SoberTimeEstimatorTests: XCTestCase {

    private let now = Date(timeIntervalSinceReferenceDate: 0)
    private let profile = BACProfile(weightKg: 70, sex: .male, standardDrinkGrams: 14)

    func testReturnsReferenceWhenAlreadySober() {
        let estimator = SoberTimeEstimator(timeline: BACTimeline(drinks: [], profile: profile))
        XCTAssertEqual(estimator.time(reaching: 0.0, after: now), now)
    }

    /// 70 kg male, 4 std drinks at t=0 → peak 0.1176 % at t=0.
    /// Reaches 0.05 about 4.5 h later, sober (0.0) about 7.84 h later.
    func testReachesTargetsForFourDrinks() {
        let drink = Drink(timestamp: now, ethanolGrams: 56, wasScheduled: true)
        let timeline = BACTimeline(drinks: [drink], profile: profile)
        let estimator = SoberTimeEstimator(timeline: timeline)
        let estimates = estimator.estimates(after: now)

        guard let below05 = estimates.belowDriving0_05 else {
            return XCTFail("Should reach 0.05")
        }
        XCTAssertEqual(below05.timeIntervalSince(now) / 3600, 4.5, accuracy: 0.1)

        guard let sober = estimates.sober else {
            return XCTFail("Should reach 0")
        }
        XCTAssertEqual(sober.timeIntervalSince(now) / 3600, 7.84, accuracy: 0.2)
    }
}

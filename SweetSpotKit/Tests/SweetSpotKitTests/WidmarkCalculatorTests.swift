import XCTest
@testable import SweetSpotKit

final class WidmarkCalculatorTests: XCTestCase {

    func testZeroEthanolReturnsZero() {
        let bac = WidmarkCalculator.bac(ethanolGrams: 0,
                                        weightKg: 70,
                                        r: 0.68,
                                        hoursElapsed: 1)
        XCTAssertEqual(bac, 0)
    }

    func testNegativeWeightOrRClampedToZero() {
        XCTAssertEqual(WidmarkCalculator.bac(ethanolGrams: 14, weightKg: 0, r: 0.68, hoursElapsed: 0), 0)
        XCTAssertEqual(WidmarkCalculator.bac(ethanolGrams: 14, weightKg: 70, r: 0, hoursElapsed: 0), 0)
    }

    /// 70 kg male, 1 std US drink (14 g), t=0.
    /// Expected ≈ (14 / (0.68 · 70 000)) · 100 = 0.02941 %
    func testSingleDrinkPeak() {
        let bac = WidmarkCalculator.bac(ethanolGrams: 14,
                                        weightKg: 70,
                                        r: 0.68,
                                        hoursElapsed: 0)
        XCTAssertEqual(bac, 0.02941, accuracy: 0.0005)
    }

    /// 70 kg male, 2 std drinks at t=0, evaluated at t=1h.
    /// (28 / (0.68 · 70 000)) · 100 = 0.05882%, minus 0.015 = 0.04382%
    func testTwoDrinksAfterOneHour() {
        let bac = WidmarkCalculator.bac(ethanolGrams: 28,
                                        weightKg: 70,
                                        r: 0.68,
                                        hoursElapsed: 1)
        XCTAssertEqual(bac, 0.04382, accuracy: 0.0005)
    }

    /// 60 kg female, 1 std drink, peak.
    /// (14 / (0.55 · 60 000)) · 100 = 0.04242%
    func testFemaleHigherBAC() {
        let bac = WidmarkCalculator.bac(ethanolGrams: 14,
                                        weightKg: 60,
                                        r: BiologicalSex.female.widmarkR,
                                        hoursElapsed: 0)
        XCTAssertEqual(bac, 0.04242, accuracy: 0.0005)
    }

    func testEliminationFullyClampsAtZero() {
        let bac = WidmarkCalculator.bac(ethanolGrams: 14,
                                        weightKg: 70,
                                        r: 0.68,
                                        hoursElapsed: 1000)
        XCTAssertEqual(bac, 0)
    }

    func testHoursToZero() {
        XCTAssertEqual(WidmarkCalculator.hoursToZero(from: 0.06), 4.0, accuracy: 0.001)
        XCTAssertEqual(WidmarkCalculator.hoursToZero(from: 0), 0)
    }
}

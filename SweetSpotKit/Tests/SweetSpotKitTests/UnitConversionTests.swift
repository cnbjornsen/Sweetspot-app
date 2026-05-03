import XCTest
@testable import SweetSpotKit

final class UnitConversionTests: XCTestCase {

    func testWeightRoundtripKilogramsPounds() {
        for kg in stride(from: 35.0, through: 250.0, by: 5.0) {
            let lb = WeightConversion.kilogramsToPounds(kg)
            let back = WeightConversion.poundsToKilograms(lb)
            XCTAssertEqual(back, kg, accuracy: 1e-9, "kg=\(kg)")
        }
    }

    func testVolumeRoundtripFlozMilliliters() {
        for floz in stride(from: 1.0, through: 64.0, by: 0.5) {
            let ml = VolumeConversion.fluidOuncesToMilliliters(floz)
            let back = VolumeConversion.millilitersToFluidOunces(ml)
            XCTAssertEqual(back, floz, accuracy: 1e-9, "floz=\(floz)")
        }
    }

    func testWeightBoundsAccept() {
        XCTAssertTrue(WeightBounds.isValidKg(35))
        XCTAssertTrue(WeightBounds.isValidKg(70))
        XCTAssertTrue(WeightBounds.isValidKg(250))
        XCTAssertTrue(WeightBounds.isValidLb(80))
        XCTAssertTrue(WeightBounds.isValidLb(550))
    }

    func testWeightBoundsReject() {
        XCTAssertFalse(WeightBounds.isValidKg(34.9))
        XCTAssertFalse(WeightBounds.isValidKg(250.1))
        XCTAssertFalse(WeightBounds.isValidLb(79))
        XCTAssertFalse(WeightBounds.isValidLb(551))
    }

    func testLocaleStandardDrinkUSDefault() {
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(LocaleStandardDrink.grams(for: us), 14.0)
    }

    func testLocaleStandardDrinkUK() {
        let uk = Locale(identifier: "en_GB")
        XCTAssertEqual(LocaleStandardDrink.grams(for: uk), 8.0)
    }

    func testLocaleStandardDrinkAU() {
        let au = Locale(identifier: "en_AU")
        XCTAssertEqual(LocaleStandardDrink.grams(for: au), 10.0)
    }

    func testLocaleStandardDrinkUnknownFallsBackToUS() {
        let xx = Locale(identifier: "xx_XX")
        XCTAssertEqual(LocaleStandardDrink.grams(for: xx), 14.0)
    }
}

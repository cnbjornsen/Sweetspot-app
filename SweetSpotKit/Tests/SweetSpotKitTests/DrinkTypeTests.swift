import XCTest
@testable import SweetSpotKit

final class DrinkTypeTests: XCTestCase {

    private let usProfile = BACProfile(weightKg: 70, sex: .male, standardDrinkGrams: 14)
    private let ukProfile = BACProfile(weightKg: 70, sex: .male, standardDrinkGrams: 8)

    func testStandardBeerIsOneStandardDrink() {
        XCTAssertEqual(DrinkType.beer12oz.ethanolGrams(profile: usProfile), 14)
        XCTAssertEqual(DrinkType.beer12oz.ethanolGrams(profile: ukProfile), 8)
    }

    func testWaterContributesNothing() {
        XCTAssertEqual(DrinkType.water.ethanolGrams(profile: usProfile), 0)
        XCTAssertFalse(DrinkType.water.contributesToBAC)
    }

    func testDoublePourMultiplier() {
        let override = DrinkSizeOverride(multiplier: 2.0)
        XCTAssertEqual(DrinkType.shot15oz.ethanolGrams(profile: usProfile,
                                                       override: override), 28)
    }

    func testCustomEthanolPassedThrough() {
        let override = DrinkSizeOverride(multiplier: 1.0, customEthanolGrams: 22)
        XCTAssertEqual(DrinkType.custom.ethanolGrams(profile: usProfile,
                                                     override: override), 22)
    }

    func testCustomWithMultiplier() {
        let override = DrinkSizeOverride(multiplier: 1.5, customEthanolGrams: 20)
        XCTAssertEqual(DrinkType.custom.ethanolGrams(profile: usProfile,
                                                     override: override), 30)
    }
}

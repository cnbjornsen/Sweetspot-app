import XCTest
@testable import SweetSpotKit

final class QuoteLibraryTests: XCTestCase {

    func testReturnsQuoteForEveryMood() {
        let library = QuoteLibrary.shared
        library.resetSessionMemory()
        for mood in QuoteMood.allCases {
            XCTAssertNotNil(library.random(for: mood),
                            "Missing fallback for mood \(mood)")
        }
    }

    func testRecentSuppressionFavorsUnseen() {
        let library = QuoteLibrary.shared
        library.resetSessionMemory()
        var seen = Set<UUID>()
        // Pull many encouraging quotes; with multiple in pool, repeats should
        // only happen after we've cycled through.
        for _ in 0..<5 {
            if let q = library.random(for: .encouraging) {
                seen.insert(q.id)
            }
        }
        XCTAssertGreaterThan(seen.count, 1,
            "Expected variety across pulls")
    }

    func testDailyQuoteIsStable() {
        let library = QuoteLibrary.shared
        let day = Date(timeIntervalSinceReferenceDate: 100_000)
        let a = library.dailyQuote(for: .encouraging, on: day)
        let b = library.dailyQuote(for: .encouraging, on: day)
        XCTAssertEqual(a?.id, b?.id)
    }

    func testOccasionTemplatesNonEmpty() {
        let occasions = OccasionTemplates.makeOccasions()
        XCTAssertFalse(occasions.isEmpty)
        XCTAssertTrue(occasions.allSatisfy(\.isTemplate))
    }
}

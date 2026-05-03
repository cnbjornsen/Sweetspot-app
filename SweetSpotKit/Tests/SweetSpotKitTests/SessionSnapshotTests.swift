import XCTest
@testable import SweetSpotKit

final class SessionSnapshotTests: XCTestCase {

    func testRoundtripCodable() throws {
        let original = SessionSnapshot(
            sessionID: UUID(),
            occasionName: "Wedding",
            state: .waiting,
            nextDrinkAt: Date(timeIntervalSinceReferenceDate: 1000),
            drinkCount: 3,
            waterCount: 1,
            currentBAC: 0.042,
            peakBAC: 0.049,
            soberAt: Date(timeIntervalSinceReferenceDate: 5000),
            plannedEndAt: Date(timeIntervalSinceReferenceDate: 4000),
            quote: "Pace = poise.",
            updatedAt: Date(timeIntervalSinceReferenceDate: 500)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(SessionSnapshot.self, from: data)

        XCTAssertEqual(restored, original)
    }

    func testEmptySnapshotIsIdle() {
        XCTAssertEqual(SessionSnapshot.empty.state, .idle)
        XCTAssertNil(SessionSnapshot.empty.sessionID)
        XCTAssertEqual(SessionSnapshot.empty.drinkCount, 0)
    }
}

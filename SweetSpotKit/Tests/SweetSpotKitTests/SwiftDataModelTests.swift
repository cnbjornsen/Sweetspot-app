import XCTest
import SwiftData
@testable import SweetSpotKit

final class SwiftDataModelTests: XCTestCase {

    @MainActor
    func testInsertProfileAndSession() throws {
        let container = try ModelContainer.sweetSpotInMemory()
        let context = ModelContext(container)

        let profile = UserProfile(weightKg: 70,
                                  sex: .male,
                                  unitSystem: .metric,
                                  standardDrinkGrams: 14)
        context.insert(profile)

        let occasion = Occasion(name: "Wedding", emoji: "💍")
        context.insert(occasion)

        let now = Date()
        let session = Session(startedAt: now,
                              plannedEndAt: now.addingTimeInterval(4 * 3600),
                              mode: .evenlyPaced(start: now,
                                                 end: now.addingTimeInterval(4 * 3600)),
                              occasion: occasion)
        context.insert(session)

        let drink = DrinkEvent(timestamp: now,
                               type: .beer12oz,
                               ethanolGrams: 14,
                               wasScheduled: true,
                               session: session)
        context.insert(drink)

        try context.save()

        let fetchedProfiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetchedProfiles.count, 1)
        XCTAssertEqual(fetchedProfiles.first?.bacProfile.weightKg, 70)

        let fetchedSessions = try context.fetch(FetchDescriptor<Session>())
        XCTAssertEqual(fetchedSessions.count, 1)
        XCTAssertEqual(fetchedSessions.first?.drinks.count, 1)
        XCTAssertEqual(fetchedSessions.first?.drinks.first?.type, .beer12oz)
        XCTAssertEqual(fetchedSessions.first?.mode?.start, now)
    }

    @MainActor
    func testActiveSessionPredicate() throws {
        let container = try ModelContainer.sweetSpotInMemory()
        let context = ModelContext(container)

        let now = Date()
        let active = Session(startedAt: now,
                             plannedEndAt: now.addingTimeInterval(3600),
                             mode: .evenlyPaced(start: now,
                                                end: now.addingTimeInterval(3600)))
        let ended = Session(startedAt: now.addingTimeInterval(-7200),
                            plannedEndAt: now.addingTimeInterval(-3600),
                            mode: .evenlyPaced(start: now.addingTimeInterval(-7200),
                                               end: now.addingTimeInterval(-3600)))
        ended.endedAt = now.addingTimeInterval(-3500)
        context.insert(active)
        context.insert(ended)
        try context.save()

        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        let result = try context.fetch(descriptor)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, active.id)
    }
}

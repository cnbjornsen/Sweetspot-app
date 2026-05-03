#if canImport(AppIntents)
import AppIntents
import Foundation
import SwiftData

/// Logs the next scheduled drink. Wired to the Live Activity / Dynamic Island
/// "I had one" button so users can log without opening the app.
@available(iOS 17.0, watchOS 10.0, *)
public struct LogDrinkIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log next drink"
    public static var description = IntentDescription(
        "Logs the drink the planner had scheduled for now."
    )
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        try await IntentRunner.logScheduledDrink()
        return .result()
    }
}

@available(iOS 17.0, watchOS 10.0, *)
public struct LogExtraIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log extra drink"
    public static var description = IntentDescription(
        "Records an unscheduled drink (a shot, an extra glass) so the planner re-paces."
    )
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Drink type")
    public var typeRaw: String

    public init() {
        self.typeRaw = DrinkType.shot15oz.rawValue
    }

    public init(type: DrinkType) {
        self.typeRaw = type.rawValue
    }

    public func perform() async throws -> some IntentResult {
        let type = DrinkType(rawValue: typeRaw) ?? .shot15oz
        try await IntentRunner.logExtraDrink(type: type)
        return .result()
    }
}

@available(iOS 17.0, watchOS 10.0, *)
public struct LogWaterIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log water"
    public static var description = IntentDescription(
        "Records a glass of water — doesn't move BAC but keeps your stats honest."
    )
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        try await IntentRunner.logWater()
        return .result()
    }
}

/// Shared SwiftData write path used by all three intents. Lives in this file
/// so the iOS app and widget extension both link it.
@available(iOS 17.0, watchOS 10.0, *)
enum IntentRunner {
    @MainActor
    static func logScheduledDrink() async throws {
        let context = try makeContext()
        guard let session = try findActiveSession(in: context),
              let profile = try findProfile(in: context) else { return }
        let event = DrinkEvent(
            timestamp: .now,
            type: .beer12oz,
            ethanolGrams: DrinkType.beer12oz.ethanolGrams(profile: profile.bacProfile),
            wasScheduled: true,
            session: session
        )
        context.insert(event)
        try context.save()
        post(.drinkLogged)
    }

    @MainActor
    static func logExtraDrink(type: DrinkType) async throws {
        let context = try makeContext()
        guard let session = try findActiveSession(in: context),
              let profile = try findProfile(in: context) else { return }
        let event = DrinkEvent(
            timestamp: .now,
            type: type,
            ethanolGrams: type.ethanolGrams(profile: profile.bacProfile),
            wasScheduled: false,
            session: session
        )
        context.insert(event)
        try context.save()
        post(.extraLogged)
    }

    @MainActor
    static func logWater() async throws {
        let context = try makeContext()
        guard let session = try findActiveSession(in: context) else { return }
        let event = DrinkEvent(
            timestamp: .now,
            type: .water,
            ethanolGrams: 0,
            wasScheduled: false,
            session: session
        )
        context.insert(event)
        try context.save()
        post(.waterLogged)
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
        let container = try ModelContainer.sweetSpotShared()
        return ModelContext(container)
    }

    @MainActor
    private static func findActiveSession(in context: ModelContext) throws -> Session? {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil }
        )
        return try context.fetch(descriptor).first
    }

    @MainActor
    private static func findProfile(in context: ModelContext) throws -> UserProfile? {
        try context.fetch(FetchDescriptor<UserProfile>()).first
    }

    private static func post(_ note: IntentBridgeNotification) {
        let name = CFNotificationName(note.rawValue as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name, nil, nil, true)
    }
}
#endif

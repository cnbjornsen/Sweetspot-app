import Foundation

/// Pre-seeded occasion library inserted on first launch so the picker isn't
/// empty. Users can rename, favorite, or delete any of these.
public enum OccasionTemplates {
    public struct Template: Hashable, Sendable {
        public let id: UUID
        public let name: String
        public let emoji: String

        public init(id: UUID, name: String, emoji: String) {
            self.id = id
            self.name = name
            self.emoji = emoji
        }
    }

    public static let all: [Template] = [
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
              name: "Friday night", emoji: "🌙"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
              name: "Date night", emoji: "💘"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
              name: "Wedding", emoji: "💍"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
              name: "Concert", emoji: "🎤"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
              name: "Birthday", emoji: "🎂"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!,
              name: "Game day", emoji: "🏈"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000007")!,
              name: "Brunch", emoji: "🥞"),
        .init(id: UUID(uuidString: "10000000-0000-0000-0000-000000000008")!,
              name: "Holiday party", emoji: "🎄"),
    ]

    /// Build SwiftData `Occasion`s from the templates. Caller inserts into
    /// the `ModelContext` if no occasions exist yet.
    public static func makeOccasions() -> [Occasion] {
        all.map { template in
            Occasion(id: template.id,
                     name: template.name,
                     emoji: template.emoji,
                     lastUsedAt: .distantPast,
                     isTemplate: true)
        }
    }
}

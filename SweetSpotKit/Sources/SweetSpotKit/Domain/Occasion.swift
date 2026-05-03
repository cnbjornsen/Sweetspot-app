import Foundation
import SwiftData

@Model
public final class Occasion {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var emoji: String?
    public var lastUsedAt: Date
    public var isFavorite: Bool
    /// True for pre-seeded templates (Friday night, Wedding, etc.).
    public var isTemplate: Bool

    @Relationship(deleteRule: .nullify, inverse: \Session.occasion)
    public var sessions: [Session] = []

    public init(id: UUID = UUID(),
                name: String,
                emoji: String? = nil,
                lastUsedAt: Date = .now,
                isFavorite: Bool = false,
                isTemplate: Bool = false) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.isTemplate = isTemplate
    }
}

import Foundation

public enum QuoteMood: String, Codable, CaseIterable, Sendable {
    case encouraging   // mid-session, in the band
    case cautionary    // mid-interval prompt, after extras
    case fanfare       // when next drink unlocks
    case stat          // post-session detail
    case onboarding    // welcome / setup screens
}

public struct Quote: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let mood: QuoteMood
    /// Higher weight = more likely to be drawn. Default 1.
    public var weight: Int

    public init(id: UUID = UUID(),
                text: String,
                mood: QuoteMood,
                weight: Int = 1) {
        self.id = id
        self.text = text
        self.mood = mood
        self.weight = weight
    }
}

public struct Meme: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    /// Image asset name in the iOS app's `Assets.xcassets/Memes/` catalog.
    public let assetName: String
    public let caption: String
    public let mood: QuoteMood

    public init(id: UUID = UUID(),
                assetName: String,
                caption: String,
                mood: QuoteMood) {
        self.id = id
        self.assetName = assetName
        self.caption = caption
        self.mood = mood
    }
}

import Foundation
import SwiftData

public extension ModelContainer {
    /// The single SwiftData container shared by the iOS app, widget extension,
    /// and (when applicable) the App Intents running inside the widget process.
    /// Stored in the App Group container so all processes see the same data.
    /// Falls back to a private in-app store if the App Group isn't configured —
    /// useful for previews and unit tests.
    static func sweetSpotShared() throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            Occasion.self,
            Session.self,
            DrinkEvent.self,
        ])

        let configuration: ModelConfiguration
        if let url = AppGroup.swiftDataStoreURL {
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// In-memory container for SwiftUI previews and tests.
    static func sweetSpotInMemory() throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            Occasion.self,
            Session.self,
            DrinkEvent.self,
        ])
        let configuration = ModelConfiguration(schema: schema,
                                               isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

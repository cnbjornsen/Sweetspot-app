import Foundation
import SwiftData
import SweetSpotKit

/// Inserts the pre-seeded `OccasionTemplates` into SwiftData on first launch
/// so the picker is never empty.
enum OccasionSeeder {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Occasion>()
        guard let count = try? context.fetchCount(descriptor), count == 0 else {
            return
        }
        for occasion in OccasionTemplates.makeOccasions() {
            context.insert(occasion)
        }
        try? context.save()
    }
}

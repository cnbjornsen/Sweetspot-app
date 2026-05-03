import Foundation
import SwiftData
import SweetSpotKit

/// On launch, finds any `Session` left active (no `endedAt`) so the
/// `SessionController` can reattach to it. If the planned end date plus the
/// watchdog grace has elapsed, the session is auto-ended and marked as such.
enum SessionHydrator {

    struct Result: Sendable {
        var session: Session?
        var didAutoEnd: Bool
    }

    @MainActor
    static func hydrate(in context: ModelContext,
                        profile: UserProfile?,
                        now: Date = .now) throws -> Result {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        guard let session = try context.fetch(descriptor).first else {
            return Result(session: nil, didAutoEnd: false)
        }

        let graceHours = max(1, profile?.watchdogGraceHours ?? 2)
        let cutoff = session.plannedEndAt.addingTimeInterval(Double(graceHours) * 3600)
        if now > cutoff {
            session.endedAt = now
            session.endReason = .auto
            session.autoEnded = true
            try context.save()
            return Result(session: nil, didAutoEnd: true)
        }
        return Result(session: session, didAutoEnd: false)
    }
}

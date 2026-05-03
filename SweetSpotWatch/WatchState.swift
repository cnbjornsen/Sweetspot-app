import Foundation
import Observation
import SweetSpotKit

@Observable
@MainActor
final class WatchState {
    var snapshot: SessionSnapshot = .empty
    var lastFiredFanfareSlot: Date?
    var isReachable: Bool = false

    var stale: Bool {
        Date.now.timeIntervalSince(snapshot.updatedAt) > 5 * 60
    }
}

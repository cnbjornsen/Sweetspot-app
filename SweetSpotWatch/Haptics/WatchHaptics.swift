import Foundation
import WatchKit
import SweetSpotKit

enum WatchHaptics {
    /// Fires a tactile alert if the next drink slot has just elapsed and we
    /// haven't already fired for that slot. Idempotent.
    @MainActor
    static func fireIfDue(snapshot: SessionSnapshot, state: WatchState) {
        guard let next = snapshot.nextDrinkAt, next <= .now else { return }
        guard state.lastFiredFanfareSlot != next else { return }
        state.lastFiredFanfareSlot = next
        WKInterfaceDevice.current().play(.notification)
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            WKInterfaceDevice.current().play(.success)
        }
    }
}

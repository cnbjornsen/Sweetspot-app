import Foundation
import SweetSpotKit

/// Listens for the Darwin notifications that `LogDrinkIntent`/`LogExtraIntent`/
/// `LogWaterIntent` post when they run inside the widget extension's process.
/// Calls back on the main actor so `SessionController` can reconcile.
final class IntentBridgeListener: @unchecked Sendable {
    static let shared = IntentBridgeListener()

    private var observers: [CFNotificationName: ObserverToken] = [:]
    private let lock = NSLock()
    private var handler: (@Sendable (IntentBridgeNotification) -> Void)?

    private init() {}

    func start(handler: @escaping @Sendable (IntentBridgeNotification) -> Void) {
        lock.lock()
        self.handler = handler
        lock.unlock()

        for note in [IntentBridgeNotification.drinkLogged,
                     .extraLogged,
                     .waterLogged] {
            register(note)
        }
    }

    private func register(_ note: IntentBridgeNotification) {
        let name = CFNotificationName(note.rawValue as CFString)
        let unmanaged = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            unmanaged,
            { _, observer, name, _, _ in
                guard let observer, let nameValue = name?.rawValue as? String,
                      let event = IntentBridgeNotification(rawValue: nameValue) else { return }
                let listener = Unmanaged<IntentBridgeListener>
                    .fromOpaque(observer)
                    .takeUnretainedValue()
                listener.fire(event)
            },
            note.rawValue as CFString,
            nil,
            .deliverImmediately)
    }

    private func fire(_ event: IntentBridgeNotification) {
        let h: (@Sendable (IntentBridgeNotification) -> Void)?
        lock.lock(); h = handler; lock.unlock()
        h?(event)
    }
}

private struct ObserverToken {}

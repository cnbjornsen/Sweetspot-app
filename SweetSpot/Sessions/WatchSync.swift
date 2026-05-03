import Foundation
import WatchConnectivity
import SweetSpotKit

/// iOS-side WatchConnectivity bridge. Pushes the latest `SessionSnapshot`
/// to the watch on every reconcile, and routes incoming watch commands
/// (logScheduled / logExtra / logWater) back into the `SessionController`.
final class WatchSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchSync()

    private static let payloadKey = "snapshot"
    var onCommand: (@Sendable (Command) -> Void)?

    enum Command: Sendable {
        case logScheduled
        case logExtra(DrinkType)
        case logWater
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func push(_ snapshot: SessionSnapshot) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        let payload: [String: Any] = [Self.payloadKey: data]
        try? session.updateApplicationContext(payload)
        // Guaranteed-delivery copy for "next drink" pings:
        if snapshot.state == .readyForDrink {
            session.transferUserInfo(payload)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo)
    }

    private func handle(_ payload: [String: Any]) {
        guard let command = payload["command"] as? String else { return }
        switch command {
        case "logScheduled":
            onCommand?(.logScheduled)
        case "logExtra":
            let typeRaw = (payload["type"] as? String) ?? DrinkType.shot15oz.rawValue
            let type = DrinkType(rawValue: typeRaw) ?? .shot15oz
            onCommand?(.logExtra(type))
        case "logWater":
            onCommand?(.logWater)
        default:
            break
        }
    }
}

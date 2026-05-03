import Foundation
import WatchConnectivity
import SweetSpotKit

/// Receives `SessionSnapshot` updates from the iPhone and forwards them to
/// the watch UI. Sends button-press events back to the iPhone when the user
/// logs from the watch.
final class WatchSessionManager: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchSessionManager()

    var onSnapshot: (@Sendable (SessionSnapshot) -> Void)?

    private static let payloadKey = "snapshot"

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: Send

    func sendLogScheduled() {
        sendCommand(["command": "logScheduled"])
    }

    func sendLogExtra(type: DrinkType) {
        sendCommand(["command": "logExtra", "type": type.rawValue])
    }

    func sendLogWater() {
        sendCommand(["command": "logWater"])
    }

    private func sendCommand(_ message: [String: Any]) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                // Fall back to guaranteed delivery on failure.
                session.transferUserInfo(message)
            }
        } else {
            session.transferUserInfo(message)
        }
    }

    // MARK: Receive

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        deliver(payload: applicationContext)
    }

    func session(_ session: WCSession,
                 didReceiveUserInfo userInfo: [String: Any] = [:]) {
        deliver(payload: userInfo)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        deliver(payload: message)
    }

    private func deliver(payload: [String: Any]) {
        guard let raw = payload[Self.payloadKey] as? Data,
              let snapshot = try? JSONDecoder.iso8601.decode(SessionSnapshot.self,
                                                             from: raw) else { return }
        onSnapshot?(snapshot)
    }
}

private extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

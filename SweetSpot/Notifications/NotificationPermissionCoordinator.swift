import Foundation
import UserNotifications
import Observation

@Observable
@MainActor
final class NotificationPermissionCoordinator {
    private(set) var status: UNAuthorizationStatus = .notDetermined

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        status = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge,
                                                .timeSensitive])
            await refreshAuthorization()
            return granted
        } catch {
            await refreshAuthorization()
            return false
        }
    }

    var isAuthorized: Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    var isDenied: Bool { status == .denied }
}

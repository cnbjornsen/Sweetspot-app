import Foundation
import UserNotifications

/// Plays the sound and shows a banner even when the app is foregrounded so
/// the user gets the same fanfare experience whether they're staring at the
/// app or have it locked.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    /// Posted whenever a Sweet Spot notification fires (foreground or tap).
    /// `ActiveSessionView` listens to drive confetti when the app is open.
    static let confettiTriggerName = Notification.Name("SweetSpot.ConfettiTrigger")

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier == NotificationScheduler.nextDrinkIdentifier {
            NotificationCenter.default.post(name: Self.confettiTriggerName, object: nil)
        }
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == NotificationScheduler.nextDrinkIdentifier {
            NotificationCenter.default.post(name: Self.confettiTriggerName, object: nil)
        }
        completionHandler()
    }
}

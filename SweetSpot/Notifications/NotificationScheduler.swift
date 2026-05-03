import Foundation
import UserNotifications

/// Schedules a single "next drink" local notification at a time.
/// Cancel + reschedule on every state change keeps things consistent.
struct NotificationScheduler {
    static let nextDrinkIdentifier = "sweetspot.next-drink"
    static let midIntervalIdentifier = "sweetspot.mid-interval"
    static let sessionAutoEndIdentifier = "sweetspot.session-auto-end"

    private let center = UNUserNotificationCenter.current()

    func rescheduleNextDrinkNotification(at fireDate: Date?) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.nextDrinkIdentifier])
        guard let fireDate, fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Sweet Spot"
        content.body = "Time for your next drink 🍻"
        content.sound = UNNotificationSound(named: .init("fanfare.caf"))
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "SWEETSPOT_NEXT_DRINK"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false)

        let request = UNNotificationRequest(
            identifier: Self.nextDrinkIdentifier,
            content: content,
            trigger: trigger)
        center.add(request)
    }

    func scheduleMidIntervalCheck(after seconds: TimeInterval) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.midIntervalIdentifier])
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Quick check-in"
        content.body = "Did you have anything extra? Be honest — your morning self will thank you."
        content.sound = .default
        content.categoryIdentifier = "SWEETSPOT_MID_CHECK"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.midIntervalIdentifier,
            content: content,
            trigger: trigger)
        center.add(request)
    }

    func scheduleSessionAutoEndPrompt(at fireDate: Date) {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.sessionAutoEndIdentifier])
        guard fireDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Session still going?"
        content.body = "Tap to wrap up and see your stats."
        content.sound = .default
        content.categoryIdentifier = "SWEETSPOT_AUTO_END"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, fireDate.timeIntervalSinceNow),
            repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.sessionAutoEndIdentifier,
            content: content,
            trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.nextDrinkIdentifier,
            Self.midIntervalIdentifier,
            Self.sessionAutoEndIdentifier,
        ])
    }
}

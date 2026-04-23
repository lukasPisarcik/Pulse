import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func deliver(kind: BreakKind, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title(for: kind)
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pulse.\(kind.rawValue).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }

    private func title(for kind: BreakKind) -> String {
        switch kind {
        case .eyeRest:   return "Pip: eye rest"
        case .movement:  return "Pip: time to move"
        case .hydration: return "Pip: hydration check"
        case .windDown:  return "Pip: wind down"
        }
    }
}

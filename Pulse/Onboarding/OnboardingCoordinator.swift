import Foundation
import SwiftUI
import UserNotifications

/// Drives onboarding: owns permission prompts and the finish handoff back to
/// AppDelegate. Held by the onboarding window; released when onboarding closes.
@MainActor
final class OnboardingCoordinator: ObservableObject {
    let store: SettingsStore
    private let calendar: CalendarBridge
    private let notifier: NotificationManager
    private let onFinish: () -> Void
    private let onSkipConfirmed: () -> Void
    private var hasResolved: Bool = false

    @Published var calendarGranted: Bool = false
    @Published var notificationsGranted: Bool = false

    init(
        store: SettingsStore,
        calendar: CalendarBridge,
        notifier: NotificationManager,
        onFinish: @escaping () -> Void,
        onSkipConfirmed: @escaping () -> Void
    ) {
        self.store = store
        self.calendar = calendar
        self.notifier = notifier
        self.onFinish = onFinish
        self.onSkipConfirmed = onSkipConfirmed
        self.calendarGranted = calendar.isAuthorized
        Task { await refreshNotificationStatus() }
    }

    func refreshNotificationStatus() async {
        let status = await notifier.authorizationStatus()
        notificationsGranted = (status == .authorized || status == .provisional)
    }

    func requestCalendar() async {
        let granted = await calendar.requestAccess()
        calendarGranted = granted
    }

    func requestNotifications() async {
        let granted = await notifier.requestAuthorization()
        notificationsGranted = granted
    }

    func finish() {
        guard !hasResolved else { return }
        hasResolved = true
        store.hasCompletedOnboarding = true
        onFinish()
    }

    func confirmSkip() {
        guard !hasResolved else { return }
        hasResolved = true
        store.hasCompletedOnboarding = true
        onSkipConfirmed()
    }
}

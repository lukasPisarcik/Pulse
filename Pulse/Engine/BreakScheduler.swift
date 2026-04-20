import Foundation
import Combine
import SwiftData

@MainActor
final class BreakScheduler: ObservableObject {
    private let engine: WellnessEngine
    private let tracker: FocusTracker
    private let calendar: CalendarBridge
    private let store: SettingsStore
    private let notifier: NotificationManager

    private var tickTimer: Timer?
    private var snoozeUntil: Date?
    private var lastEyeRestTrigger: Date?
    private var lastMovementTrigger: Date?
    private var lastHydrationTrigger: Date?
    private var lastWindDownTrigger: Date?

    var modelContext: ModelContext?

    init(
        engine: WellnessEngine,
        tracker: FocusTracker,
        calendar: CalendarBridge,
        store: SettingsStore,
        notifier: NotificationManager
    ) {
        self.engine = engine
        self.tracker = tracker
        self.calendar = calendar
        self.store = store
        self.notifier = notifier
    }

    func start() {
        tickTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tickTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func snooze(minutes: Int) {
        snoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        engine.snooze(minutes: minutes)
    }

    func recordBreak(kind: BreakKind) {
        engine.recordBreak(kind: kind)
        persistBreak(kind: kind, snoozed: false)
        switch kind {
        case .eyeRest:   lastEyeRestTrigger = Date()
        case .movement:  lastMovementTrigger = Date()
        case .hydration: lastHydrationTrigger = Date()
        case .windDown:  lastWindDownTrigger = Date()
        }
    }

    private func tick() {
        let userActive = !tracker.isUserIdle
        engine.tickOneMinute(userActive: userActive)

        guard shouldEvaluate() else { return }
        if calendar.isInMeeting() { return }
        if let until = snoozeUntil, until > Date() { return }

        evaluateBreakTriggers()
    }

    private func shouldEvaluate() -> Bool {
        guard store.isWithinWorkingHours(now: Date()) else { return false }
        guard store.isActiveToday(now: Date()) else { return false }
        return true
    }

    private func evaluateBreakTriggers() {
        let now = Date()

        if dueForTrigger(last: lastEyeRestTrigger, intervalMinutes: store.eyeRestIntervalMinutes, now: now) {
            fire(kind: .eyeRest)
            lastEyeRestTrigger = now
            return
        }
        if dueForTrigger(last: lastMovementTrigger, intervalMinutes: store.movementIntervalMinutes, now: now) {
            fire(kind: .movement)
            lastMovementTrigger = now
            return
        }
        if dueForTrigger(last: lastHydrationTrigger, intervalMinutes: store.hydrationIntervalMinutes, now: now) {
            fire(kind: .hydration)
            lastHydrationTrigger = now
            return
        }
        if store.windDownEnabled, store.isWindDownTime(now: now),
           dueForTrigger(last: lastWindDownTrigger, intervalMinutes: 60, now: now) {
            fire(kind: .windDown)
            lastWindDownTrigger = now
        }
    }

    private func dueForTrigger(last: Date?, intervalMinutes: Int, now: Date) -> Bool {
        guard let last else { return engine.minutesSinceBreak >= intervalMinutes }
        return now.timeIntervalSince(last) >= TimeInterval(intervalMinutes * 60)
    }

    private func fire(kind: BreakKind) {
        let message = NotificationTemplates.random(for: kind)
        engine.lastMessage = message
        notifier.deliver(kind: kind, message: message)
    }

    private func persistBreak(kind: BreakKind, snoozed: Bool) {
        guard let modelContext else { return }
        let record = BreakRecord(
            timestamp: Date(),
            type: kind.rawValue,
            triggered: true,
            snoozed: snoozed,
            pipState: engine.pipState.rawValue
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}

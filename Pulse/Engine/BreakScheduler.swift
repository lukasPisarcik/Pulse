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
    private var isPaused: Bool = false

    private var currentDayKey: String = BreakScheduler.dayKey(for: Date())
    private var dayBreakCount: Int = 0
    private var dayPeakFocusStreak: Int = 0
    private var dayScoreSum: Int = 0
    private var dayScoreSamples: Int = 0

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
            Task { @MainActor in await self?.tick() }
        }
        tickTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func pauseForSystemEvent() {
        isPaused = true
    }

    func resumeFromSystemEvent() {
        isPaused = false
    }

    func snooze(minutes: Int) {
        snoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        engine.snooze(minutes: minutes)
    }

    func recordBreak(kind: BreakKind) {
        engine.recordBreak(kind: kind)
        persistBreak(kind: kind, snoozed: false)
        dayBreakCount += 1
        switch kind {
        case .eyeRest:   lastEyeRestTrigger = Date()
        case .movement:  lastMovementTrigger = Date()
        case .hydration: lastHydrationTrigger = Date()
        case .windDown:  lastWindDownTrigger = Date()
        }
    }

    private func tick() async {
        rolloverIfNeeded()

        guard !isPaused else { return }

        tracker.setIdleThreshold(minutes: store.idleThresholdMinutes)

        let userActive = !tracker.isUserIdle
        engine.tickOneMinute(userActive: userActive)

        if userActive {
            dayPeakFocusStreak = max(dayPeakFocusStreak, engine.focusStreakMinutes)
            dayScoreSum += engine.wellnessScore
            dayScoreSamples += 1
        }

        guard shouldEvaluate() else { return }
        if store.pauseDuringMeetings, await calendar.isInMeeting() { return }
        if store.pauseWhenIdle, !userActive { return }
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

        if store.eyeRestEnabled,
           dueForTrigger(last: lastEyeRestTrigger, intervalMinutes: store.eyeRestIntervalMinutes, now: now) {
            fire(kind: .eyeRest)
            lastEyeRestTrigger = now
            return
        }
        if store.movementEnabled,
           dueForTrigger(last: lastMovementTrigger, intervalMinutes: store.movementIntervalMinutes, now: now) {
            fire(kind: .movement)
            lastMovementTrigger = now
            return
        }
        if store.hydrationEnabled,
           dueForTrigger(last: lastHydrationTrigger, intervalMinutes: store.hydrationIntervalMinutes, now: now) {
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

    // MARK: - Daily rollover

    private func rolloverIfNeeded() {
        let today = Self.dayKey(for: Date())
        guard today != currentDayKey else { return }
        finalizeDay(forKey: currentDayKey)
        currentDayKey = today
        dayBreakCount = 0
        dayPeakFocusStreak = 0
        dayScoreSum = 0
        dayScoreSamples = 0
        engine.resetDailyCounters()
    }

    private func finalizeDay(forKey key: String) {
        guard let modelContext else { return }
        guard let date = Self.dateFromKey(key) else { return }
        let avg = dayScoreSamples > 0 ? dayScoreSum / dayScoreSamples : 100
        let session = SessionRecord(
            date: date,
            focusMinutes: engine.screenTimeMinutes,
            breakCount: dayBreakCount,
            peakFocusStreak: dayPeakFocusStreak,
            wellnessScoreAvg: avg
        )
        modelContext.insert(session)
        try? modelContext.save()
    }

    private static func dayKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private static func dateFromKey(_ key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]; comps.month = parts[1]; comps.day = parts[2]
        comps.hour = 12
        return Calendar.current.date(from: comps)
    }
}

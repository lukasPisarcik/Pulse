import Foundation
import Combine
import SwiftUI

@MainActor
final class WellnessEngine: ObservableObject {
    @Published var state: WellnessState = .flow
    @Published var pipState: PipState = .flow
    @Published var focusStreakMinutes: Int = 0
    @Published var minutesSinceBreak: Int = 0
    @Published var screenTimeMinutes: Int = 0
    @Published var wellnessScore: Int = 100
    @Published var lastMessage: String = ""

    private var breakTakenResetTask: Task<Void, Never>?

    func tickOneMinute(userActive: Bool) {
        if userActive {
            focusStreakMinutes += 1
            minutesSinceBreak += 1
            screenTimeMinutes += 1
        }
        updateStateFromMetrics()
    }

    func resetDailyCounters() {
        focusStreakMinutes = 0
        screenTimeMinutes = 0
    }

    func computeScore() -> Int {
        let penalty = min(minutesSinceBreak, 180)
        let raw = 100 - Int((Double(penalty) / 180.0) * 60)
        return max(0, min(100, raw))
    }

    func updateStateFromMetrics() {
        switch minutesSinceBreak {
        case 0..<90:   state = .flow;    if pipState != .breakTaken { pipState = .flow }
        case 90..<150: state = .headsUp; if pipState != .breakTaken { pipState = .headsUp }
        default:       state = .restNow; if pipState != .breakTaken { pipState = .restNow }
        }
        wellnessScore = computeScore()
    }

    func recordBreak(kind: BreakKind) {
        minutesSinceBreak = 0
        focusStreakMinutes = 0
        pipState = .breakTaken
        lastMessage = NotificationTemplates.random(for: .breakTaken)

        breakTakenResetTask?.cancel()
        breakTakenResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                guard let self else { return }
                self.updateStateFromMetrics()
            }
        }
    }

    func snooze(minutes: Int) {
        minutesSinceBreak = max(0, minutesSinceBreak - minutes)
        updateStateFromMetrics()
    }
}

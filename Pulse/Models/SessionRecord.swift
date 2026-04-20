import Foundation
import SwiftData

@Model
final class SessionRecord {
    var date: Date
    var focusMinutes: Int
    var breakCount: Int
    var peakFocusStreak: Int
    var wellnessScoreAvg: Int

    init(
        date: Date,
        focusMinutes: Int = 0,
        breakCount: Int = 0,
        peakFocusStreak: Int = 0,
        wellnessScoreAvg: Int = 100
    ) {
        self.date = date
        self.focusMinutes = focusMinutes
        self.breakCount = breakCount
        self.peakFocusStreak = peakFocusStreak
        self.wellnessScoreAvg = wellnessScoreAvg
    }
}

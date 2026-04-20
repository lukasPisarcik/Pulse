import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("launchAtLogin")            var launchAtLogin: Bool = true
    @AppStorage("showPipInNotch")           var showPipInNotch: Bool = true
    @AppStorage("pipAnimationsEnabled")     var pipAnimationsEnabled: Bool = true
    @AppStorage("showStreak")               var showStreak: Bool = true
    @AppStorage("showClock")                var showClock: Bool = true

    @AppStorage("eyeRestIntervalMinutes")   var eyeRestIntervalMinutes: Int = 20
    @AppStorage("movementIntervalMinutes")  var movementIntervalMinutes: Int = 90
    @AppStorage("hydrationIntervalMinutes") var hydrationIntervalMinutes: Int = 60
    @AppStorage("windDownEnabled")          var windDownEnabled: Bool = true
    @AppStorage("windDownStartHour")        var windDownStartHour: Int = 20
    @AppStorage("snoozeMinutes")            var snoozeMinutes: Int = 15

    @AppStorage("workingHoursStart")        var workingHoursStart: Int = 9
    @AppStorage("workingHoursEnd")          var workingHoursEnd: Int = 18
    @AppStorage("activeDaysMask")           var activeDaysMask: Int = 0b0111110 // Mon–Fri

    @AppStorage("pipMessageTone")           var pipMessageTone: String = "warm" // warm | direct | minimal
    @AppStorage("pipSpeaksIn")              var pipSpeaksIn: String = "both"    // notch | notifications | both

    @AppStorage("usageAnalytics")           var usageAnalytics: Bool = false

    func isWithinWorkingHours(now: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= workingHoursStart && hour < workingHoursEnd
    }

    func isActiveToday(now: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: now) // 1=Sun
        let bit = (weekday - 1)
        return (activeDaysMask >> bit) & 1 == 1
    }

    func isWindDownTime(now: Date) -> Bool {
        guard windDownEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= windDownStartHour
    }

    func toggleDay(_ weekday: Int) {
        let bit = 1 << weekday
        activeDaysMask ^= bit
    }

    func dayEnabled(_ weekday: Int) -> Bool {
        (activeDaysMask >> weekday) & 1 == 1
    }
}

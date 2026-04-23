import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("hasCompletedOnboarding")   var hasCompletedOnboarding: Bool = false

    @AppStorage("launchAtLogin")            var launchAtLogin: Bool = true
    @AppStorage("showMenuBarIcon")          var showMenuBarIcon: Bool = false
    @AppStorage("soundEffects")             var soundEffects: Bool = true
    @AppStorage("notificationStyle")        var notificationStyle: String = "notchOnly"
    @AppStorage("showWellnessScore")        var showWellnessScore: Bool = true
    @AppStorage("urgencyThreshold")         var urgencyThreshold: String = "medium"
    @AppStorage("showPipInNotch")           var showPipInNotch: Bool = true
    @AppStorage("pipAnimationsEnabled")     var pipAnimationsEnabled: Bool = true
    @AppStorage("showStreak")               var showStreak: Bool = true
    @AppStorage("showClock")                var showClock: Bool = true

    @AppStorage("eyeRestEnabled")           var eyeRestEnabled: Bool = true
    @AppStorage("eyeRestInterval")          var eyeRestIntervalMinutes: Int = 45
    @AppStorage("movementEnabled")          var movementEnabled: Bool = true
    @AppStorage("movementInterval")         var movementIntervalMinutes: Int = 60
    @AppStorage("hydrationEnabled")         var hydrationEnabled: Bool = true
    @AppStorage("hydrationInterval")        var hydrationIntervalMinutes: Int = 45
    @AppStorage("neverInterruptFlow")       var neverInterruptFlow: Bool = true
    @AppStorage("windDownEnabled")          var windDownEnabled: Bool = true
    @AppStorage("windDownHour")             var windDownStartHour: Int = 20
    @AppStorage("windDownMinute")           var windDownMinute: Int = 30
    @AppStorage("snoozeMinutes")            var snoozeMinutes: Int = 15

    @AppStorage("workStartHour")            var workingHoursStart: Int = 9
    @AppStorage("workStartMinute")          var workStartMinute: Int = 0
    @AppStorage("workEndHour")              var workingHoursEnd: Int = 18
    @AppStorage("workEndMinute")            var workEndMinute: Int = 0
    @AppStorage("pauseDuringMeetings")      var pauseDuringMeetings: Bool = true
    @AppStorage("pauseWhenIdle")            var pauseWhenIdle: Bool = true
    @AppStorage("idleThresholdMinutes")     var idleThresholdMinutes: Int = 5
    @AppStorage("weekendMode")              var weekendMode: Bool = false
    @AppStorage("activeDaysMask")           var activeDaysMask: Int = 0b0111110 // Mon–Fri

    @AppStorage("glowEnabled")              var glowEnabled: Bool = true
    @AppStorage("glowIntensity")            var glowIntensity: Double = 6.0
    @AppStorage("outerBloomEnabled")        var outerBloomEnabled: Bool = true
    @AppStorage("sideAmbientInfo")          var sideAmbientInfo: Bool = true
    @AppStorage("miniProgressBar")          var miniProgressBar: Bool = true
    @AppStorage("expandTrigger")            var expandTrigger: String = "both"
    @AppStorage("customAccentEnabled")      var customAccentEnabled: Bool = false
    @AppStorage("customAccentHex")          var customAccentHex: String = "A97FD4"

    @AppStorage("localProcessingOnly")      var localProcessingOnly: Bool = true
    @AppStorage("crashReports")             var crashReports: Bool = false
    @AppStorage("storeHistory")             var storeHistory: Bool = true
    @AppStorage("retentionDays")            var retentionDays: Int = 90

    @AppStorage("pipMessageTone")           var pipMessageTone: String = "warm" // warm | direct | minimal
    @AppStorage("pipSpeaksIn")              var pipSpeaksIn: String = "both"    // notch | notifications | both

    @AppStorage("usageAnalytics")           var usageAnalytics: Bool = false

    func isWithinWorkingHours(now: Date) -> Bool {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let nowMinutes = hour * 60 + minute
        let start = workingHoursStart * 60 + workStartMinute
        let end = workingHoursEnd * 60 + workEndMinute

        if start == end { return true }
        if start < end {
            return nowMinutes >= start && nowMinutes < end
        }
        return nowMinutes >= start || nowMinutes < end
    }

    func isActiveToday(now: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: now) // 1=Sun
        let bit = (weekday - 1)
        return (activeDaysMask >> bit) & 1 == 1
    }

    func isWindDownTime(now: Date) -> Bool {
        guard windDownEnabled else { return false }
        let cal = Calendar.current
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let windDownStart = windDownStartHour * 60 + windDownMinute
        return nowMinutes >= windDownStart
    }

    func toggleDay(_ weekday: Int) {
        let bit = 1 << weekday
        activeDaysMask ^= bit
    }

    func dayEnabled(_ weekday: Int) -> Bool {
        (activeDaysMask >> weekday) & 1 == 1
    }
}

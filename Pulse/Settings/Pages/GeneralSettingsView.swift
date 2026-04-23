import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    let onRerunOnboarding: () -> Void
    let onApplyLaunchAtLogin: () -> Void
    let onApplyMenuBarVisibility: () -> Void

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $store.launchAtLogin)
                    .onChange(of: store.launchAtLogin) { _, _ in
                        onApplyLaunchAtLogin()
                    }
                Toggle("Show menu bar icon fallback", isOn: $store.showMenuBarIcon)
                    .onChange(of: store.showMenuBarIcon) { _, _ in
                        onApplyMenuBarVisibility()
                    }
                Toggle("Sound effects", isOn: $store.soundEffects)
            }

            Section("Reminder style") {
                Picker("Notification style", selection: $store.notificationStyle) {
                    Text("Notch only").tag("notchOnly")
                    Text("Notch + banner").tag("notchAndBanner")
                    Text("Banner only").tag("bannerOnly")
                }
                Picker("Urgency threshold", selection: $store.urgencyThreshold) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
                Toggle("Show wellness score in hover", isOn: $store.showWellnessScore)
            }

            Section("Notch extras") {
                Toggle("Show Pip in notch", isOn: $store.showPipInNotch)
                Toggle("Animate Pip", isOn: $store.pipAnimationsEnabled)
                Toggle("Show focus streak", isOn: $store.showStreak)
                Toggle("Show clock", isOn: $store.showClock)
            }

            Section("Onboarding") {
                Button {
                    onRerunOnboarding()
                } label: {
                    Label("Rerun onboarding", systemImage: "arrow.clockwise")
                }
            }
        }
        .formStyle(.grouped)
    }
}

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $store.launchAtLogin)
            }

            Section("Appearance") {
                Toggle("Show Pip in notch", isOn: $store.showPipInNotch)
                Toggle("Animate Pip", isOn: $store.pipAnimationsEnabled)
                Toggle("Show focus streak", isOn: $store.showStreak)
                Toggle("Show clock", isOn: $store.showClock)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0 (1)")
                LabeledContent("Mascot", value: "Pip the owl")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

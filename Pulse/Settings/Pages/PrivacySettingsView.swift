import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        Form {
            Section("Data") {
                LabeledContent("All data stored") {
                    Text("On this Mac").foregroundStyle(.secondary)
                }
                LabeledContent("Cloud sync") {
                    Text("Off (v1)").foregroundStyle(.secondary)
                }
                Toggle("Anonymous usage analytics", isOn: $store.usageAnalytics)
            }

            Section("Calendar") {
                Text("Pulse reads your calendar locally to avoid interrupting you during meetings. No calendar data ever leaves your Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Open System Settings → Privacy → Calendars") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section("Notifications") {
                Button("Open notification settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Privacy")
    }
}

import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    let onDeleteWellnessData: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            Section {
                Text("All data stays on your Mac. Nothing is ever uploaded, synced, or shared.")
                    .font(.callout)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.vertical, 6)
            }

            Section("Privacy controls") {
                Toggle("Local processing only", isOn: .constant(true))
                    .disabled(true)
                Toggle("Crash reports", isOn: $store.crashReports)
                Toggle("Store wellness history", isOn: $store.storeHistory)
                Picker("Retention period", selection: $store.retentionDays) {
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                    Text("1 year").tag(365)
                    Text("Forever").tag(-1)
                }
            }

            Section("Data actions") {
                Button("Delete all wellness data", role: .destructive) {
                    showDeleteConfirm = true
                }
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
        .alert("Delete all wellness data?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDeleteWellnessData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes local break and session history. This action cannot be undone.")
        }
    }
}

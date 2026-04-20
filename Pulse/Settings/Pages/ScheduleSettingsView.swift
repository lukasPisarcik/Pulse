import SwiftUI

struct ScheduleSettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        Form {
            Section("Working hours") {
                HStack {
                    Text("Start")
                    Spacer()
                    Picker("", selection: $store.workingHoursStart) {
                        ForEach(0..<24) { h in
                            Text(hourLabel(h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                HStack {
                    Text("End")
                    Spacer()
                    Picker("", selection: $store.workingHoursEnd) {
                        ForEach(1..<25) { h in
                            Text(hourLabel(h == 24 ? 0 : h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }

            Section("Active days") {
                HStack(spacing: 8) {
                    ForEach(0..<7) { day in
                        DayToggle(
                            label: weekdayLabels[day],
                            isOn: store.dayEnabled(day),
                            action: { store.toggleDay(day) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Wind-down") {
                Toggle("Enable wind-down reminders", isOn: $store.windDownEnabled)
                HStack {
                    Text("Start at")
                    Spacer()
                    Picker("", selection: $store.windDownStartHour) {
                        ForEach(17..<24) { h in
                            Text(hourLabel(h)).tag(h)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    .disabled(!store.windDownEnabled)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Schedule")
    }

    private func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(hour12):00 \(suffix)"
    }
}

struct DayToggle: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? Color.white : Color.secondary)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(isOn ? Color.pulseGreen : Color.gray.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

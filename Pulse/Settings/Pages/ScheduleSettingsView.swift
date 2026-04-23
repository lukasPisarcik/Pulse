import SwiftUI

struct ScheduleSettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    private let weekdayOrder = [1, 2, 3, 4, 5, 6, 0] // Mon...Sun
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        Form {
            Section("Working hours") {
                DatePicker("Start", selection: startDateBinding, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: endDateBinding, displayedComponents: .hourAndMinute)
            }

            Section("Active days") {
                HStack(spacing: 8) {
                    ForEach(Array(weekdayOrder.enumerated()), id: \.offset) { index, day in
                        DayToggle(
                            label: weekdayLabels[index],
                            isOn: store.dayEnabled(day),
                            action: { store.toggleDay(day) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Focus protections") {
                Toggle("Pause during meetings", isOn: $store.pauseDuringMeetings)
                Toggle("Pause when idle", isOn: $store.pauseWhenIdle)
                if store.pauseWhenIdle {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Idle threshold: \(store.idleThresholdMinutes) min")
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(store.idleThresholdMinutes) },
                                set: { store.idleThresholdMinutes = Int($0) }
                            ),
                            in: 3...10,
                            step: 1
                        )
                    }
                }
            }

            Section("Wind-down") {
                Toggle("Enable evening wind-down", isOn: $store.windDownEnabled)
                DatePicker("Start time", selection: windDownDateBinding, displayedComponents: .hourAndMinute)
                    .disabled(!store.windDownEnabled)
                Toggle("Weekend mode", isOn: $store.weekendMode)
            }
        }
        .formStyle(.grouped)
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { date(hour: store.workingHoursStart, minute: store.workStartMinute) },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.workingHoursStart = comps.hour ?? store.workingHoursStart
                store.workStartMinute = comps.minute ?? store.workStartMinute
            }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { date(hour: store.workingHoursEnd, minute: store.workEndMinute) },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.workingHoursEnd = comps.hour ?? store.workingHoursEnd
                store.workEndMinute = comps.minute ?? store.workEndMinute
            }
        )
    }

    private var windDownDateBinding: Binding<Date> {
        Binding(
            get: { date(hour: store.windDownStartHour, minute: store.windDownMinute) },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.windDownStartHour = comps.hour ?? store.windDownStartHour
                store.windDownMinute = comps.minute ?? store.windDownMinute
            }
        )
    }

    private func date(hour: Int, minute: Int) -> Date {
        let now = Date()
        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) ?? now
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

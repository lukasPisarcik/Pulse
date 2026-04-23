import SwiftUI

struct BreaksSettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        Form {
            Section("Break intervals") {
                Toggle("Eye rest reminders", isOn: $store.eyeRestEnabled)
                breakSlider(
                    label: "Eye rest",
                    icon: "eye",
                    value: $store.eyeRestIntervalMinutes,
                    range: 15...90
                )
                .disabled(!store.eyeRestEnabled)
                .opacity(store.eyeRestEnabled ? 1 : 0.5)

                Toggle("Movement reminders", isOn: $store.movementEnabled)
                breakSlider(
                    label: "Movement",
                    icon: "figure.walk",
                    value: $store.movementIntervalMinutes,
                    range: 30...120
                )
                .disabled(!store.movementEnabled)
                .opacity(store.movementEnabled ? 1 : 0.5)

                Toggle("Hydration reminders", isOn: $store.hydrationEnabled)
                breakSlider(
                    label: "Hydration",
                    icon: "drop",
                    value: $store.hydrationIntervalMinutes,
                    range: 30...90
                )
                .disabled(!store.hydrationEnabled)
                .opacity(store.hydrationEnabled ? 1 : 0.5)
            }

            Section("Behavior") {
                Toggle("Never interrupt flow", isOn: $store.neverInterruptFlow)

                HStack {
                    Text("Snooze duration")
                    Spacer()
                    Picker("", selection: $store.snoozeMinutes) {
                        ForEach([5, 10, 15, 20, 30], id: \.self) { m in
                            Text("\(m) min").tag(m)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func breakSlider(
        label: String,
        icon: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Text("every \(value.wrappedValue) min")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 5
            )
        }
        .padding(.vertical, 2)
    }
}

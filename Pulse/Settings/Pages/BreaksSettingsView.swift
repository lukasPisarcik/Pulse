import SwiftUI

struct BreaksSettingsView: View {
    @EnvironmentObject private var store: SettingsStore

    var body: some View {
        Form {
            Section("Break intervals") {
                breakSlider(
                    label: "Eye rest",
                    icon: "eye",
                    value: $store.eyeRestIntervalMinutes,
                    range: 10...60
                )
                breakSlider(
                    label: "Movement",
                    icon: "figure.walk",
                    value: $store.movementIntervalMinutes,
                    range: 30...180
                )
                breakSlider(
                    label: "Hydration",
                    icon: "drop",
                    value: $store.hydrationIntervalMinutes,
                    range: 20...180
                )
            }

            Section("Snooze") {
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
        .navigationTitle("Breaks")
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

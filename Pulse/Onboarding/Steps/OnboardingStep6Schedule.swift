import SwiftUI

struct OnboardingStep6Schedule: View {
    @EnvironmentObject private var store: SettingsStore
    let onFinish: () -> Void

    private let weekdayOrder = [1, 2, 3, 4, 5, 6, 0] // Mon...Sun (store uses 0=Sun)
    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("When do you work?")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("Pulse will only nudge you during your hours")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("Set your typical working hours and active days. You can always adjust this later in Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }
            .padding(.top, 12)

            VStack(spacing: 16) {
                section("Working hours") {
                    HStack(spacing: 10) {
                        hourPicker(selection: $store.workingHoursStart, label: "Start")
                        Text("to")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.45))
                        hourPicker(selection: $store.workingHoursEnd, label: "End")
                    }
                }

                section("Active days") {
                    HStack(spacing: 8) {
                        ForEach(Array(weekdayOrder.enumerated()), id: \.offset) { index, day in
                            dayToggle(day: day, label: weekdayLabels[index])
                        }
                    }
                }

                section("Evening wind-down") {
                    HStack(spacing: 10) {
                        Toggle("", isOn: $store.windDownEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                        hourPicker(selection: $store.windDownStartHour, label: "Start")
                            .disabled(!store.windDownEnabled)
                            .opacity(store.windDownEnabled ? 1 : 0.4)
                    }
                }
            }
            .padding(.horizontal, 60)

            Spacer(minLength: 0)

            Button(action: onFinish) {
                HStack(spacing: 6) {
                    Text("Start using Pulse")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
        }
        .padding(.top, 12)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.5))
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
        }
    }

    private func hourPicker(selection: Binding<Int>, label: String) -> some View {
        Picker(label, selection: selection) {
            ForEach(0..<24) { h in
                Text(Self.hourLabel(h)).tag(h)
            }
        }
        .labelsHidden()
        .frame(width: 110)
    }

    private func dayToggle(day: Int, label: String) -> some View {
        let enabled = store.dayEnabled(day)
        return Button(action: { store.toggleDay(day) }) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(enabled ? Color.white : Color.white.opacity(0.5))
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(enabled ? Color.pulseGreen : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }

    private static func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(hour12):00 \(suffix)"
    }
}

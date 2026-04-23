import SwiftUI

struct NotchSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: WellnessEngine
    private let accentSwatches = ["A97FD4", "8B5FBF", "6B3FA0", "FF6B9D", "FF4757", "378ADD"]

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Border glow", isOn: $store.glowEnabled)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glow intensity: \(Int(store.glowIntensity))")
                        .foregroundStyle(.secondary)
                    Slider(value: $store.glowIntensity, in: 1...10, step: 1)
                }
                .disabled(!store.glowEnabled)
                .opacity(store.glowEnabled ? 1 : 0.5)

                Toggle("Outer bloom", isOn: $store.outerBloomEnabled)
                Toggle("Side ambient info", isOn: $store.sideAmbientInfo)
                Toggle("Mini progress bar", isOn: $store.miniProgressBar)

                Picker("Expand trigger", selection: $store.expandTrigger) {
                    Text("Hover").tag("hover")
                    Text("Click").tag("click")
                    Text("Both").tag("both")
                }

                Toggle("Custom accent override", isOn: $store.customAccentEnabled)
                if store.customAccentEnabled {
                    HStack(spacing: 10) {
                        ForEach(accentSwatches, id: \.self) { hex in
                            Button {
                                store.customAccentHex = hex
                            } label: {
                                Circle()
                                    .fill(color(for: hex))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(store.customAccentHex == hex ? 0.95 : 0.2),
                                                lineWidth: store.customAccentHex == hex ? 2 : 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Legacy toggles") {
                Toggle("Show focus streak", isOn: $store.showStreak)
                Toggle("Show clock", isOn: $store.showClock)
                Toggle("Show Pip in notch", isOn: $store.showPipInNotch)
            }

            Section("Preview") {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black)
                                .frame(width: 160, height: 34)
                            HStack(spacing: 6) {
                                if store.showPipInNotch {
                                    PipMiniView(state: engine.pipState, width: 18, height: 20)
                                }
                                BreathingDot(color: engine.state.color, duration: 2.0)
                                    .frame(width: 7, height: 7)
                                Text(engine.state.label)
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(engine.state.color)
                            }
                        }
                        Text("Live preview of current state")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }

    private func color(for hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = UInt32(sanitized, radix: 16) else { return .pulsePurple }
        return Color(hex: value)
    }
}

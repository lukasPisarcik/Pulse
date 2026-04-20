import SwiftUI

struct NotchSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: WellnessEngine

    var body: some View {
        Form {
            Section("Display") {
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
        .navigationTitle("Notch")
    }
}

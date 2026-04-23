import SwiftUI

struct PipSettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: WellnessEngine

    @State private var previewState: PipState = .flow

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Show Pip in notch", isOn: $store.showPipInNotch)
                Toggle("Pip animations", isOn: $store.pipAnimationsEnabled)

                Picker("Pip speaks in", selection: $store.pipSpeaksIn) {
                    Text("Notch").tag("notch")
                    Text("Notifications").tag("notifications")
                    Text("Both").tag("both")
                }

                Picker("Message tone", selection: $store.pipMessageTone) {
                    Text("Warm").tag("warm")
                    Text("Direct").tag("direct")
                    Text("Minimal").tag("minimal")
                }
            }

            Section("Preview") {
                VStack(spacing: 16) {
                    PipView(state: previewState, size: 120,
                            animationsEnabled: store.pipAnimationsEnabled)
                        .frame(height: 140)

                    Picker("State", selection: $previewState) {
                        ForEach(PipState.allCases, id: \.self) { s in
                            Text(stateLabel(s)).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 8)
            }
        }
        .formStyle(.grouped)
    }

    private func stateLabel(_ s: PipState) -> String {
        switch s {
        case .flow:       return "Flow"
        case .headsUp:    return "Heads-up"
        case .restNow:    return "Rest"
        case .breakTaken: return "Break"
        }
    }
}

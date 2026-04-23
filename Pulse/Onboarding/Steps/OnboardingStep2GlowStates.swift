import SwiftUI

struct OnboardingStep2GlowStates: View {
    let onNext: () -> Void

    @State private var demoState: WellnessState = .flow
    @State private var demoTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Three states, one glance")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("You always know how you're doing without opening anything")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("Pulse changes color and breathing speed based on how long you've been working. Green means flow. Amber means a nudge is forming. Red means your body needs a reset.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }
            .padding(.top, 12)

            VStack(spacing: 14) {
                row(state: .flow,    caption: "< 90 min since break")
                row(state: .headsUp, caption: "90–150 min since break")
                row(state: .restNow, caption: "150+ min since break")
            }
            .padding(.top, 4)

            Text("The pill sits at the top of your screen at all times. No windows to open.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.45))
                .padding(.top, 4)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button("Play demo", action: startDemo)
                    .buttonStyle(SecondaryPillButtonStyle())
                Button("Continue", action: onNext)
                    .buttonStyle(PrimaryPillButtonStyle())
            }
        }
        .padding(.top, 12)
        .onDisappear { demoTask?.cancel() }
    }

    private func row(state: WellnessState, caption: String) -> some View {
        HStack(spacing: 18) {
            NotchPillPreview(state: demoState == state || !isDemoRunning ? state : state,
                             size: CGSize(width: 148, height: 34),
                             showLabel: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(state.color)
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(.horizontal, 36)
        .opacity(rowOpacity(for: state))
        .animation(.easeInOut(duration: 0.4), value: demoState)
    }

    private var isDemoRunning: Bool { demoTask != nil }

    private func rowOpacity(for state: WellnessState) -> Double {
        guard isDemoRunning else { return 1.0 }
        return demoState == state ? 1.0 : 0.4
    }

    private func startDemo() {
        demoTask?.cancel()
        demoTask = Task { @MainActor in
            let sequence: [WellnessState] = [.flow, .headsUp, .restNow, .flow]
            for s in sequence {
                demoState = s
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if Task.isCancelled { break }
            }
            demoTask = nil
        }
    }
}

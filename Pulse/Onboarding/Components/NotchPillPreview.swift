import SwiftUI

/// Reusable mini notch pill used across onboarding (steps 1 & 2). Visually
/// mirrors the plain-wings pill layout but sized for centred hero display on
/// a dark backdrop, with its own ambient glow instead of the window-level one.
struct NotchPillPreview: View {
    let state: WellnessState
    var size: CGSize = CGSize(width: 168, height: 40)
    var showPip: Bool = true
    var showLabel: Bool = true
    var animationsEnabled: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
                .fill(state.color.opacity(0.38))
                .blur(radius: 22)
                .frame(width: size.width + 24, height: size.height + 18)

            RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
                        .stroke(state.color.opacity(0.5), lineWidth: 0.8)
                )
                .shadow(color: state.color.opacity(0.45), radius: 14)

            HStack(spacing: 8) {
                if showPip {
                    PipMiniView(state: pipState, width: 20, height: 22)
                }
                BreathingDot(color: state.color, duration: animationsEnabled ? state.pulseDuration : 10_000)
                    .frame(width: 7, height: 7)
                if showLabel {
                    Text(state.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(state.color)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(width: size.width, height: size.height)
        .animation(.easeInOut(duration: 0.5), value: state)
    }

    private var pipState: PipState {
        switch state {
        case .flow:    return .flow
        case .headsUp: return .headsUp
        case .restNow: return .restNow
        }
    }
}

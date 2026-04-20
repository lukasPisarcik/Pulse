import SwiftUI

struct NotchIdleView: View {
    @ObservedObject var engine: WellnessEngine
    @ObservedObject var store: SettingsStore

    var body: some View {
        HStack(spacing: 0) {
            if store.showStreak {
                Text("\(engine.focusStreakMinutes)m focus")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 64, alignment: .trailing)
                    .padding(.trailing, 8)
            } else {
                Spacer().frame(width: 72)
            }

            notchPill
                .frame(width: 130, height: 32)

            if store.showClock {
                Text(currentTime)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 64, alignment: .leading)
                    .padding(.leading, 8)
            } else {
                Spacer().frame(width: 72)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notchPill: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.92))

            HStack(spacing: 6) {
                if store.showPipInNotch {
                    PipMiniView(state: engine.pipState, width: 18, height: 20)
                }

                BreathingDot(color: engine.state.color, duration: engine.state.pulseDuration)
                    .frame(width: 7, height: 7)

                Text(engine.state.label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(engine.state.color)

                MiniWellnessBar(score: engine.wellnessScore, color: engine.state.color)
                    .frame(width: 36, height: 2)
            }
            .padding(.horizontal, 10)
        }
    }

    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}

struct BreathingDot: View {
    let color: Color
    let duration: Double
    @State private var scale: CGFloat = 0.88

    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = 1.15
                }
            }
    }
}

struct MiniWellnessBar: View {
    let score: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(score) / 100)
                    .animation(.easeOut(duration: 0.6), value: score)
            }
        }
    }
}

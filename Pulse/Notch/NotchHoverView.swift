import SwiftUI

struct NotchHoverView: View {
    @ObservedObject var engine: WellnessEngine

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pulsePurple.opacity(0.45), lineWidth: 1)
                )

            HStack(spacing: 0) {
                statCol(title: "Focus", value: "\(engine.focusStreakMinutes)m")
                divider
                statCol(title: "Since break", value: formatMinutes(engine.minutesSinceBreak))
                divider
                statCol(title: "Screen today", value: formatMinutes(engine.screenTimeMinutes))
                divider
                statCol(title: "Wellness", value: "\(engine.wellnessScore)")
            }
            .padding(.horizontal, 12)

            VStack {
                PipMiniView(state: engine.pipState, width: 22, height: 24)
                    .offset(y: -10)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    private func statCol(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 20)
    }

    private func formatMinutes(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }
}

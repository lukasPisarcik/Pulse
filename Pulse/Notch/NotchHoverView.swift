import SwiftUI

/// Four-column stats strip, drawn below the notch band on notched Macs.
/// Wings (Pip + streak) and the background pill are drawn by `NotchRootView`.
struct NotchHoverView: View {
    @ObservedObject var engine: WellnessEngine

    var body: some View {
        HStack(spacing: 0) {
            stat(value: "\(engine.focusStreakMinutes)m",
                 label: "focus",
                 color: .pulseGreen)
            divider
            stat(value: formatHours(engine.minutesSinceBreak),
                 label: "no break",
                 color: .pulseAmber)
            divider
            stat(value: formatHours(engine.screenTimeMinutes, compact: true),
                 label: "today",
                 color: Color.white.opacity(0.7))
            divider
            stat(value: "\(engine.wellnessScore)",
                 label: "wellness",
                 color: .pulsePurple)
        }
        .padding(.top, 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 0.5, height: 22)
    }

    private func formatHours(_ m: Int, compact: Bool = false) -> String {
        if compact {
            let h = Double(m) / 60.0
            if h < 1 { return "\(m)m" }
            return String(format: "%.1fh", h)
        }
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h\(rem)m"
    }
}

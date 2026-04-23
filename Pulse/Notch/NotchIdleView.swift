import SwiftUI

/// Breathing indicator dot — solid circle whose scale pulses between 0.88 and 1.15
/// at the given duration. Used in the pill's wing alongside Pip.
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

/// Tiny 0–100 wellness fill bar — used inside the pill on non-notched Macs to
/// mirror the mockup's in-notch progress indicator.
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

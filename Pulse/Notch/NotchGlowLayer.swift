import SwiftUI

/// SwiftUI glow that traces the notch pill in three layered passes:
///  * `outerBloom` — wide, heavily blurred copy of the pill shape, bleeds onto the
///    menu bar. Breathes in opacity at `pulseDuration`.
///  * `halo` — soft wider stroke, blurred; gives the pill a colored atmosphere.
///  * `rim` — crisp 1.5pt stroke flush with the pill edge.
///
/// Uses `NotchShape` so it follows the same flat-top / rounded-bottom silhouette
/// as the pill itself on notched Macs, and fully rounds on non-notched Macs when
/// `topCornerRadius == bottomCornerRadius`.
struct NotchGlowBackground: View {
    let color: Color
    let pulseDuration: Double
    let pillSize: CGSize
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat

    @State private var breathing = false

    var body: some View {
        ZStack {
            outerBloom
            halo
            rim
        }
        // Pin this view to the pill's bounds so the rim/halo layers align exactly
        // with the pill background. The bloom intentionally oversizes itself inside
        // and overflows this frame (SwiftUI doesn't clip by default).
        //
        // Color/size transitions inherit the parent's spring so the glow morphs in
        // lockstep with the pill — no explicit `.animation` here.
        .frame(width: pillSize.width, height: pillSize.height)
        .onAppear { startBreathing() }
        .onChange(of: pulseDuration) { _, _ in restartBreathing() }
    }

    private var outerBloom: some View {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius + 8
        )
        .fill(color)
        .frame(width: pillSize.width + 18, height: pillSize.height + 14)
        .blur(radius: 14)
        .opacity(breathing ? 0.30 : 0.62)
        .offset(y: -2)
        .allowsHitTesting(false)
    }

    private var halo: some View {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
        .stroke(color, lineWidth: 4)
        .frame(width: pillSize.width, height: pillSize.height)
        .blur(radius: 5)
        .opacity(0.35)
        .allowsHitTesting(false)
    }

    private var rim: some View {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
        .stroke(color.opacity(0.8), lineWidth: 1.5)
        .frame(width: pillSize.width, height: pillSize.height)
        .blur(radius: 0.4)
        .allowsHitTesting(false)
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    /// Switch breathing cadence without a visible snap: fade to the low opacity
    /// under a short ease, then hand off to the new `.repeatForever` cycle.
    private func restartBreathing() {
        withAnimation(.easeInOut(duration: 0.3)) { breathing = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}

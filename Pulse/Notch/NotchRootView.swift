import SwiftUI

/// The window is sized for the largest presentation (`.expanded`) plus glow inset
/// and never resizes. The pill inside animates size + content changes.
///
/// The persistent layers — background shape, glow, and wings (Pip + focus timer) —
/// are mounted here once and never swap, so hovering/clicking doesn't flicker them.
/// Only the state-specific extension content below the notch fades in and out.
struct NotchRootView: View {
    @ObservedObject var engine: WellnessEngine
    @ObservedObject var store: SettingsStore
    @Binding var presentation: NotchWindowController.Presentation
    let onTakeBreak: () -> Void
    let onSnooze: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void

    init(
        engine: WellnessEngine,
        store: SettingsStore,
        presentationBinding: Binding<NotchWindowController.Presentation>,
        onTakeBreak: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.engine = engine
        self.store = store
        self._presentation = presentationBinding
        self.onTakeBreak = onTakeBreak
        self.onSnooze = onSnooze
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
    }

    private var geometry: NotchGeometry {
        NotchWindowController.notchGeometry()
    }

    private var pillSize: CGSize {
        geometry.pillSize(for: presentation)
    }

    private var bottomCornerRadius: CGFloat {
        switch presentation {
        case .idle:     return geometry.hasNotch ? geometry.notchHeight * 0.55 : 14
        case .hover:    return geometry.hasNotch ? 18 : 14
        case .expanded: return geometry.hasNotch ? 22 : 18
        }
    }

    private var topCornerRadius: CGFloat {
        geometry.hasNotch ? 0 : bottomCornerRadius
    }

    private var glowColor: Color {
        switch presentation {
        case .hover:    return .pulsePurple
        case .expanded: return .pulseBlue
        case .idle:     return engine.state.color
        }
    }

    private var glowPulseDuration: Double {
        switch presentation {
        case .hover:    return 2.5
        case .expanded: return 3.0
        case .idle:     return engine.state.pulseDuration
        }
    }

    private let morph = Animation.spring(response: 0.32, dampingFraction: 0.86)

    var body: some View {
        VStack(spacing: 0) {
            pill
                .frame(width: pillSize.width, height: pillSize.height)
                .onHover { hovering in
                    guard presentation != .expanded else { return }
                    withAnimation(morph) {
                        presentation = hovering ? .hover : .idle
                    }
                }
                .onTapGesture {
                    withAnimation(morph) {
                        presentation = (presentation == .expanded) ? .idle : .expanded
                    }
                }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if presentation == .expanded {
                        withAnimation(morph) { presentation = .idle }
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(morph, value: presentation)
        .animation(morph, value: engine.state)
    }

    private var pill: some View {
        ZStack(alignment: .top) {
            NotchGlowBackground(
                color: glowColor,
                pulseDuration: glowPulseDuration,
                pillSize: pillSize,
                topCornerRadius: topCornerRadius,
                bottomCornerRadius: bottomCornerRadius
            )

            background

            if geometry.hasNotch {
                wings
            } else {
                plainWings
            }

            extensionArea
                .padding(.top, geometry.hasNotch ? geometry.notchHeight : 0)
        }
    }

    @ViewBuilder
    private var background: some View {
        if geometry.hasNotch {
            NotchShape(topCornerRadius: 0, bottomCornerRadius: bottomCornerRadius)
                .fill(Color.black)
        } else {
            RoundedRectangle(cornerRadius: bottomCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.94))
        }
    }

    /// Persistent layout for notched Macs — Pip on the left wing, timer on the right.
    /// The HStack is sized exactly to `notchHeight` and pinned to the pill's top
    /// edge by the parent `ZStack(alignment: .top)`. No flex frame here, so the
    /// wings content stays anchored in the same screen position regardless of
    /// whether the pill is idle, hovered, or expanded.
    private var wings: some View {
        HStack(spacing: 0) {
            leftWing
                .frame(width: geometry.wingWidth, height: geometry.notchHeight)

            Color.clear
                .frame(width: geometry.notchWidth, height: geometry.notchHeight)

            rightWing
                .frame(width: geometry.wingWidth, height: geometry.notchHeight)
        }
    }

    private var leftWing: some View {
        HStack(spacing: 6) {
            if store.showPipInNotch {
                PipMiniView(state: engine.pipState, width: 22, height: 24)
            }
            BreathingDot(color: engine.state.color, duration: engine.state.pulseDuration)
                .frame(width: 6, height: 6)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        // `Alignment.trailing` is (horizontal: .trailing, vertical: .center) —
        // explicit maxHeight makes the wing fill the full notch band so the
        // HStack centers its content vertically inside the cutout.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    private var rightWing: some View {
        Text(focusStreakText)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .monospacedDigit()
            // SF Pro's baseline sits near the ascender, so a centered text bbox
            // puts the digit glyphs visually above cell-center. Nudge down so
            // the glyphs line up with Pip's visual midline on the other wing.
            .offset(y: 1)
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// Focus-streak timer label. Reads as "Xm" under an hour, then switches to
    /// "Hh Mm" once a full hour has accumulated so longer sessions stay legible.
    private var focusStreakText: String {
        Self.formatFocusStreak(minutes: engine.focusStreakMinutes)
    }

    static func formatFocusStreak(minutes: Int) -> String {
        let safe = max(0, minutes)
        if safe < 60 { return "\(safe)m" }
        let hours = safe / 60
        let mins = safe % 60
        return "\(hours)h \(mins)m"
    }

    /// Persistent layout for non-notched Macs — mockup's in-pill row: Pip, dot,
    /// state label, tiny wellness-fill bar.
    private var plainWings: some View {
        HStack(spacing: 7) {
            if store.showPipInNotch {
                PipMiniView(state: engine.pipState, width: 18, height: 20)
            }
            BreathingDot(color: engine.state.color, duration: engine.state.pulseDuration)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.state.label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(engine.state.color)
                MiniWellnessBar(score: engine.wellnessScore, color: engine.state.color)
                    .frame(width: 40, height: 2)
            }
            if store.showStreak {
                Spacer(minLength: 4)
                Text(focusStreakText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var extensionArea: some View {
        switch presentation {
        case .idle:
            EmptyView()
        case .hover:
            NotchHoverView(engine: engine)
                .transition(.opacity)
        case .expanded:
            NotchExpandedView(
                engine: engine,
                onTakeBreak: {
                    onTakeBreak()
                    withAnimation(morph) { presentation = .idle }
                },
                onSnooze: {
                    onSnooze()
                    withAnimation(morph) { presentation = .idle }
                },
                onOpenSettings: {
                    onOpenSettings()
                    withAnimation(morph) { presentation = .idle }
                },
                onQuit: {
                    onQuit()
                },
                onClose: {
                    withAnimation(morph) { presentation = .idle }
                }
            )
            .transition(.opacity)
        }
    }
}

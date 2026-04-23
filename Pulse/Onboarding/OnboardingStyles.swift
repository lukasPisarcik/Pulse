import SwiftUI
import AppKit

struct PrimaryPillButtonStyle: ButtonStyle {
    var color: Color = .pulseGreen

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(color.opacity(configuration.isPressed ? 0.78 : 1.0))
            )
            .shadow(color: color.opacity(0.35), radius: 10, y: 4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.78))
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(configuration.isPressed ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5)
            )
    }
}

struct GhostTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.5 : 0.72))
    }
}

/// NSVisualEffectView wrapper used by the onboarding window's backdrop.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow
    var appearance: NSAppearance? = NSAppearance(named: .darkAqua)

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.material = material
        view.blendingMode = blending
        view.appearance = appearance
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
        nsView.appearance = appearance
    }
}

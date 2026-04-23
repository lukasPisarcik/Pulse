import SwiftUI

/// Expanded message panel drawn below the notch band.
/// Layout mirrors the mockup: dot + state label + timestamp + close,
/// body copy, pill-shaped primary/secondary actions.
struct NotchExpandedView: View {
    @ObservedObject var engine: WellnessEngine
    let onTakeBreak: () -> Void
    let onSnooze: () -> Void
    let onOpenSettings: () -> Void
    let onQuit: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Text(messageText)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.88))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
            actions
                .padding(.top, 2)
        }
        .padding(.top, 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(engine.state.color)
                .frame(width: 6, height: 6)
            Text(engine.state.label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(engine.state.color)
            Text("· \(timeString)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(3)
            }
            .buttonStyle(.plain)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Button(action: onTakeBreak) {
                    Text("Take 5-min break")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.pulseGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.pulseGreen.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onSnooze) {
                    Text("Snooze 15m")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button("Settings", action: onOpenSettings)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .buttonStyle(.plain)

                Button("Quit", action: onQuit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .buttonStyle(.plain)
            }
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }

    private var messageText: String {
        if !engine.lastMessage.isEmpty { return engine.lastMessage }
        switch engine.state {
        case .flow:    return NotificationTemplates.random(for: PipMessageKind.flowAck)
        case .headsUp: return NotificationTemplates.random(for: PipMessageKind.eyeRest)
        case .restNow: return NotificationTemplates.random(for: PipMessageKind.movement)
        }
    }
}

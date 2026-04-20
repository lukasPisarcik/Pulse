import SwiftUI

struct NotchExpandedView: View {
    @ObservedObject var engine: WellnessEngine
    let onTakeBreak: () -> Void
    let onSnooze: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.pulseBlue.opacity(0.55), lineWidth: 1)
                )

            HStack(alignment: .top, spacing: 12) {
                PipView(state: engine.pipState, size: 48)
                    .frame(width: 48, height: 54)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(engine.state.color)
                            .frame(width: 7, height: 7)
                        Text(engine.state.label.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(engine.state.color)
                        Text("•  \(engine.minutesSinceBreak)m since break")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }

                    Text(messageText)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        Button(action: onTakeBreak) {
                            Text("Take break")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.pulseGreen, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onSnooze) {
                            Text("Snooze 15m")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(6)
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
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

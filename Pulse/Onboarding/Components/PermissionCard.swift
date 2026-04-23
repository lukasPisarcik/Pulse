import SwiftUI

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let caption: String
    let primaryLabel: String
    let secondaryLabel: String
    let granted: Bool
    let busy: Bool
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 78, height: 78)
                Image(systemName: granted ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(granted ? Color.pulseGreen : iconColor)
            }
            .padding(.top, 28)

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)

            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.58))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            actions
                .padding(.top, 4)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: 380)
        .background(cardBackground)
    }

    @ViewBuilder
    private var actions: some View {
        if granted {
            Text("Access granted")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.pulseGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.pulseGreen.opacity(0.14))
                )
        } else {
            HStack(spacing: 10) {
                Button(action: onPrimary) {
                    HStack(spacing: 6) {
                        if busy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(primaryLabel)
                    }
                }
                .buttonStyle(PrimaryPillButtonStyle(color: iconColor))
                .disabled(busy)

                Button(secondaryLabel, action: onSecondary)
                    .buttonStyle(SecondaryPillButtonStyle())
                    .disabled(busy)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black.opacity(0.32))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

struct TrustSignalRow: View {
    struct Signal: Identifiable {
        let id = UUID()
        let symbol: String
        let label: String
    }

    let signals: [Signal]

    var body: some View {
        HStack(spacing: 28) {
            ForEach(signals) { s in
                VStack(spacing: 4) {
                    Image(systemName: s.symbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                    Text(s.label)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
        }
    }
}

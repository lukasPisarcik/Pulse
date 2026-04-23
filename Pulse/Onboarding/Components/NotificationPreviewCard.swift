import SwiftUI

struct NotificationPreviewCard: View {
    let dotColor: Color
    let label: String
    let time: String
    let message: String
    let primaryLabel: String
    let secondaryLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(dotColor).frame(width: 6, height: 6)
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(dotColor)
                Text("·  \(time)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.38))
                Spacer()
            }

            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                pill(text: primaryLabel, isPrimary: true)
                pill(text: secondaryLabel, isPrimary: false)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private func pill(text: String, isPrimary: Bool) -> some View {
        Text(text)
            .font(.system(size: 10, weight: isPrimary ? .semibold : .medium, design: .rounded))
            .foregroundStyle(isPrimary ? Color.pulseGreen : Color.white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Group {
                    if isPrimary {
                        Capsule().fill(Color.pulseGreen.opacity(0.14))
                    } else {
                        Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    }
                }
            )
    }
}

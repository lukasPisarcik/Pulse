import SwiftUI

struct OnboardingStep1Welcome: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            NotchPillPreview(state: .flow, size: CGSize(width: 176, height: 44))
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("Meet Pulse")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("A wellness companion that lives at the top of your screen")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.78))

                Text("Pulse turns the camera bump on your MacBook into something useful — a quiet, always-visible signal of how your body and mind are doing. Pip the owl watches over things.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }

            featurePills
                .padding(.top, 4)

            Spacer(minLength: 0)

            Button("Continue", action: onNext)
                .buttonStyle(PrimaryPillButtonStyle())
        }
        .padding(.top, 30)
    }

    private var featurePills: some View {
        HStack(spacing: 14) {
            featurePill(icon: "circle.fill", color: .pulseGreen, title: "Ambient glow", sub: "Three states, one glance")
            featurePill(icon: "timer", color: .pulseAmber, title: "Smart reminders", sub: "Timed to your body")
            featurePill(icon: "bell.slash", color: .pulsePurple, title: "Never intrusive", sub: "Pauses for meetings")
        }
    }

    private func featurePill(icon: String, color: Color, title: String, sub: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(Circle().fill(color.opacity(0.15)))
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.88))
            Text(sub)
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.48))
        }
        .frame(width: 120)
    }
}

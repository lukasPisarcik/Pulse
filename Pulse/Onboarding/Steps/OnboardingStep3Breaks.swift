import SwiftUI

struct OnboardingStep3Breaks: View {
    let onNext: () -> Void

    @State private var reveal: [Bool] = [false, false, false]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Breaks that actually make sense")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("Timed to when your body needs them, not a fixed clock")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("Pulse nudges your eyes, body, and hydration at the right times. Reminders pause automatically during meetings and when you step away.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }
            .padding(.top, 12)

            VStack(spacing: 10) {
                card(index: 0,
                     dot: .pulseGreen,
                     label: "Eyes",
                     time: "2:14 PM",
                     message: "Look 20 feet away for 20 seconds.",
                     primary: "Start eye break",
                     secondary: "Snooze 15m")
                card(index: 1,
                     dot: .pulseAmber,
                     label: "Movement",
                     time: "4:30 PM",
                     message: "Time to stand. Even two minutes resets you.",
                     primary: "Take break",
                     secondary: "Snooze 15m")
                card(index: 2,
                     dot: .pulsePurple,
                     label: "Evening",
                     time: "8:30 PM",
                     message: "Good work today. Time to close Slack.",
                     primary: "Wind down",
                     secondary: "Maybe later")
            }
            .padding(.horizontal, 40)

            Spacer(minLength: 0)

            Button("Continue", action: onNext)
                .buttonStyle(PrimaryPillButtonStyle())
        }
        .padding(.top, 12)
        .onAppear(perform: staggerReveal)
    }

    private func card(
        index: Int, dot: Color, label: String, time: String,
        message: String, primary: String, secondary: String
    ) -> some View {
        NotificationPreviewCard(
            dotColor: dot, label: label, time: time,
            message: message, primaryLabel: primary, secondaryLabel: secondary
        )
        .opacity(reveal[index] ? 1 : 0)
        .offset(y: reveal[index] ? 0 : 18)
    }

    private func staggerReveal() {
        for i in 0..<reveal.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.14) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    reveal[i] = true
                }
            }
        }
    }
}

import SwiftUI

struct OnboardingStep5Notifications: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let onAdvance: () -> Void

    @State private var busy: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Banner reminders as backup")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("For when the notch isn't visible")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("The notch is the primary way Pulse reaches you. Banner notifications are a fallback when your MacBook's built-in display isn't active.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }
            .padding(.top, 12)

            PermissionCard(
                icon: "bell",
                iconColor: .pulsePurple,
                title: "Allow Notifications",
                caption: "Only when the notch isn't visible",
                primaryLabel: "Allow Notifications",
                secondaryLabel: "Use notch only",
                granted: coordinator.notificationsGranted,
                busy: busy,
                onPrimary: requestAccess,
                onSecondary: onAdvance
            )
            .padding(.horizontal, 40)

            Spacer(minLength: 0)

            if coordinator.notificationsGranted {
                Button("Continue", action: onAdvance)
                    .buttonStyle(PrimaryPillButtonStyle())
            } else {
                Text("You can change this later in System Settings → Notifications.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.top, 12)
        .onChange(of: coordinator.notificationsGranted) { _, granted in
            if granted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onAdvance()
                }
            }
        }
    }

    private func requestAccess() {
        busy = true
        Task {
            await coordinator.requestNotifications()
            busy = false
        }
    }
}

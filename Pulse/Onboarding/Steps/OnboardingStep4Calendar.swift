import SwiftUI

struct OnboardingStep4Calendar: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    let onAdvance: () -> Void

    @State private var busy: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Pause during meetings")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("We'll never interrupt you mid-call")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("Pulse reads your calendar to automatically pause all reminders when you're in a meeting. Your calendar data never leaves your Mac.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 48)
            }
            .padding(.top, 12)

            PermissionCard(
                icon: "calendar",
                iconColor: .pulseBlue,
                title: "Allow Calendar Access",
                caption: "Read-only · Local only · Never uploaded",
                primaryLabel: "Allow Access",
                secondaryLabel: "Skip for now",
                granted: coordinator.calendarGranted,
                busy: busy,
                onPrimary: requestAccess,
                onSecondary: onAdvance
            )
            .padding(.horizontal, 40)

            TrustSignalRow(signals: [
                .init(symbol: "lock.fill",     label: "Read-only access"),
                .init(symbol: "eye.slash",     label: "Event titles only"),
                .init(symbol: "icloud.slash",  label: "Never synced")
            ])
            .padding(.top, 4)

            Spacer(minLength: 0)

            if coordinator.calendarGranted {
                Button("Continue", action: onAdvance)
                    .buttonStyle(PrimaryPillButtonStyle())
            } else {
                Text("You can enable this later in Settings → Privacy.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.top, 12)
        .onChange(of: coordinator.calendarGranted) { _, granted in
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
            await coordinator.requestCalendar()
            busy = false
        }
    }
}

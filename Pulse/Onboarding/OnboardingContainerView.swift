import SwiftUI

struct OnboardingContainerView: View {
    @ObservedObject var coordinator: OnboardingCoordinator

    @State private var step: OnboardingStep = .welcome
    @State private var advancingForward: Bool = true
    @State private var showSkipConfirm: Bool = false

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                contentCard
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                footer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .frame(width: 720, height: 560)
        .confirmationDialog(
            "Skip setup?",
            isPresented: $showSkipConfirm,
            titleVisibility: .visible
        ) {
            Button("Skip setup", role: .destructive) {
                coordinator.confirmSkip()
            }
            Button("Continue setup", role: .cancel) { }
        } message: {
            Text("You can always rerun onboarding in Settings → General.")
        }
    }

    private var backdrop: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blending: .behindWindow)
            LinearGradient(
                colors: [
                    Color.pulseNavy.opacity(0.55),
                    Color.pulseDark.opacity(0.8)
                ],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.pulsePurple.opacity(0.28), .clear],
                center: .top, startRadius: 0, endRadius: 360
            )
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            if step != .welcome {
                Button(action: goBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                    }
                }
                .buttonStyle(GhostTextButtonStyle())
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
            Spacer()
            Text("Pulse setup")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(0.6)
            Spacer()
            Button(action: { showSkipConfirm = true }) {
                Text("Skip")
            }
            .buttonStyle(GhostTextButtonStyle())
        }
    }

    private var contentCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingStep1Welcome(onNext: advance)
            case .glowStates:
                OnboardingStep2GlowStates(onNext: advance)
            case .breaks:
                OnboardingStep3Breaks(onNext: advance)
            case .calendar:
                OnboardingStep4Calendar(coordinator: coordinator, onAdvance: advance)
            case .notifications:
                OnboardingStep5Notifications(coordinator: coordinator, onAdvance: advance)
            case .schedule:
                OnboardingStep6Schedule(onFinish: coordinator.finish)
                    .environmentObject(coordinator.store)
            }
        }
        .id(step)
        .transition(.asymmetric(
            insertion: .move(edge: advancingForward ? .trailing : .leading).combined(with: .opacity),
            removal:   .move(edge: advancingForward ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    private var footer: some View {
        VStack(spacing: 12) {
            OnboardingProgressDots(
                total: OnboardingStep.total,
                currentIndex: step.index,
                onTapCompleted: { i in
                    if let target = OnboardingStep(rawValue: i) {
                        advancingForward = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            step = target
                        }
                    }
                }
            )
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                Text("Are you sure? You can always rerun onboarding in Settings → General.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))

                Button("Skip setup") {
                    showSkipConfirm = true
                }
                .buttonStyle(GhostTextButtonStyle())
            }
        }
    }

    private func advance() {
        guard let next = step.next else {
            coordinator.finish()
            return
        }
        advancingForward = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            step = next
        }
    }

    private func goBack() {
        guard let prev = step.previous else { return }
        advancingForward = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            step = prev
        }
    }
}

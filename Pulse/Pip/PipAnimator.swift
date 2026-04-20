import SwiftUI
import Combine

@MainActor
final class PipAnimator: ObservableObject {
    @Published var isBlinking = false
    @Published var isGlowing = false
    @Published var isNodding = false
    @Published var isWaving = false

    private var blinkTask: Task<Void, Never>?
    private var glowTask: Task<Void, Never>?

    func start(for state: PipState) {
        stop()
        startBlink(interval: state.blinkInterval)
        startGlow(duration: state.glowDuration)
        isNodding = state == .restNow
        isWaving = state == .breakTaken
    }

    func stop() {
        blinkTask?.cancel()
        glowTask?.cancel()
        blinkTask = nil
        glowTask = nil
        isBlinking = false
        isGlowing = false
        isNodding = false
        isWaving = false
    }

    private func startBlink(interval: Double) {
        blinkTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.isBlinking = true }
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.isBlinking = false }
            }
        }
    }

    private func startGlow(duration: Double) {
        glowTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: duration)) {
                        self?.isGlowing.toggle()
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            }
        }
    }
}

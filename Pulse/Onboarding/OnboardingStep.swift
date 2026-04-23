import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case glowStates
    case breaks
    case calendar
    case notifications
    case schedule

    var id: Int { rawValue }
    var index: Int { rawValue }

    static var total: Int { allCases.count }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}

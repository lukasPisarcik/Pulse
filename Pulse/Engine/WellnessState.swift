import SwiftUI

enum WellnessState: String, Equatable, Codable, CaseIterable {
    case flow
    case headsUp
    case restNow

    var label: String {
        switch self {
        case .flow:    return "In flow"
        case .headsUp: return "Heads-up"
        case .restNow: return "Rest needed"
        }
    }

    var color: Color {
        switch self {
        case .flow:    return .pulseGreen
        case .headsUp: return .pulseAmber
        case .restNow: return .pulseRed
        }
    }

    var pulseDuration: Double {
        switch self {
        case .flow:    return 3.0
        case .headsUp: return 2.0
        case .restNow: return 1.4
        }
    }
}

enum BreakKind: String, Codable, CaseIterable {
    case eyeRest
    case movement
    case hydration
    case windDown

    var displayName: String {
        switch self {
        case .eyeRest:   return "Eye rest"
        case .movement:  return "Movement"
        case .hydration: return "Hydration"
        case .windDown:  return "Wind-down"
        }
    }
}

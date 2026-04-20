import SwiftUI

enum PipState: String, Equatable, CaseIterable {
    case flow
    case headsUp
    case restNow
    case breakTaken

    var eyeColor: Color {
        switch self {
        case .flow:       return .pulseGreen
        case .headsUp:    return .pulseAmber
        case .restNow:    return .pulseRed
        case .breakTaken: return .pulseGlowSparkle
        }
    }

    var glowDuration: Double {
        switch self {
        case .flow:       return 3.0
        case .headsUp:    return 2.0
        case .restNow:    return 1.4
        case .breakTaken: return 0.9
        }
    }

    var tuftAngle: Double {
        switch self {
        case .flow:       return 0
        case .headsUp:    return -10
        case .restNow:    return 18
        case .breakTaken: return -4
        }
    }

    var eyelidScale: CGFloat {
        switch self {
        case .flow:       return 1.0
        case .headsUp:    return 0.68
        case .restNow:    return 0.35
        case .breakTaken: return 1.05
        }
    }

    var blinkInterval: Double {
        switch self {
        case .flow:       return 4.0
        case .headsUp:    return 3.0
        case .restNow:    return 1.8
        case .breakTaken: return 6.0
        }
    }
}

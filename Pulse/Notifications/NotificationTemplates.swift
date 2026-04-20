import Foundation

enum PipMessageKind {
    case eyeRest
    case movement
    case hydration
    case windDown
    case flowAck
    case breakTaken
}

enum NotificationTemplates {
    static let eyeRest = [
        "Your eyes have been working hard. Look somewhere 20 feet away for 20 seconds — I'll time it.",
        "Time for the 20-20-20. Pick a distant point and let your eyes relax. Go on.",
        "I notice you haven't looked away from the screen in a while. Give your eyes a gift."
    ]
    static let movement = [
        "Even owls stretch their wings. Two minutes of movement resets everything.",
        "Stand up. Seriously — your posture will thank you later.",
        "Let's take a quick break together. Stretch, shake it out, then come back fresh."
    ]
    static let hydration = [
        "When did you last drink water? Now's a good time.",
        "I can't make you drink water, but I can remind you. This is me reminding you.",
        "Hydration check. Glass of water — go."
    ]
    static let windDown = [
        "Good work today. Closing Slack now helps your brain actually switch off.",
        "It's getting late. You've done enough — let's wind down.",
        "I'm settling in for the evening. You should too."
    ]
    static let flowAck = [
        "Deep focus detected. I'll stay quiet and keep watch.",
        "You're in the zone. I won't interrupt — see you on the other side.",
        "Great flow streak going. I'm here when you need me."
    ]
    static let breakTaken = [
        "That's it! Even a short break helps more than you think.",
        "Nice work taking that break. Your brain will run better for it.",
        "Welcome back. Ready when you are."
    ]

    static func random(for kind: BreakKind) -> String {
        switch kind {
        case .eyeRest:   return eyeRest.randomElement() ?? eyeRest[0]
        case .movement:  return movement.randomElement() ?? movement[0]
        case .hydration: return hydration.randomElement() ?? hydration[0]
        case .windDown:  return windDown.randomElement() ?? windDown[0]
        }
    }

    static func random(for kind: PipMessageKind) -> String {
        switch kind {
        case .eyeRest:    return eyeRest.randomElement() ?? eyeRest[0]
        case .movement:   return movement.randomElement() ?? movement[0]
        case .hydration:  return hydration.randomElement() ?? hydration[0]
        case .windDown:   return windDown.randomElement() ?? windDown[0]
        case .flowAck:    return flowAck.randomElement() ?? flowAck[0]
        case .breakTaken: return breakTaken.randomElement() ?? breakTaken[0]
        }
    }
}

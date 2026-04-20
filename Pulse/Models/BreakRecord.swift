import Foundation
import SwiftData

@Model
final class BreakRecord {
    var timestamp: Date
    var type: String
    var triggered: Bool
    var snoozed: Bool
    var pipState: String

    init(timestamp: Date, type: String, triggered: Bool, snoozed: Bool, pipState: String) {
        self.timestamp = timestamp
        self.type = type
        self.triggered = triggered
        self.snoozed = snoozed
        self.pipState = pipState
    }
}

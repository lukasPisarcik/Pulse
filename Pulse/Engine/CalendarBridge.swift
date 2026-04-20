import Foundation
import EventKit

@MainActor
final class CalendarBridge {
    private let store = EKEventStore()
    private(set) var hasAccess: Bool = false

    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                hasAccess = try await store.requestFullAccessToEvents()
            } catch {
                hasAccess = false
            }
        } else {
            hasAccess = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    func isInMeeting(now: Date = Date()) -> Bool {
        guard hasAccess else { return false }
        let predicate = store.predicateForEvents(
            withStart: now.addingTimeInterval(-60),
            end: now.addingTimeInterval(60),
            calendars: nil
        )
        return store.events(matching: predicate).contains { event in
            guard !event.isAllDay else { return false }
            return event.startDate <= now && event.endDate >= now
        }
    }
}

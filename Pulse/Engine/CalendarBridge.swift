import Foundation
import EventKit

final class CalendarBridge {
    private let store = EKEventStore()
    private let eventsQueue = DispatchQueue(label: "pulse.calendar.events", qos: .userInitiated)
    private(set) var hasAccess: Bool = false

    init() {
        refreshAuthorizationCache()
    }

    @discardableResult
    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                _ = try await store.requestFullAccessToEvents()
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
        refreshAuthorizationCache()
        return hasAccess
    }

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .fullAccess, .authorized:
            return true
        default:
            return false
        }
    }

    func refreshAuthorizationCache() {
        hasAccess = isAuthorized
    }

    /// EventKit fetches can occasionally block for several seconds (large
    /// calendars, account sync churn). Run this off the main thread so
    /// hover/click handling in the notch stays responsive.
    func isInMeeting(now: Date = Date()) async -> Bool {
        guard hasAccess else { return false }
        return await withCheckedContinuation { cont in
            eventsQueue.async { [store] in
                let predicate = store.predicateForEvents(
                    withStart: now.addingTimeInterval(-60),
                    end: now.addingTimeInterval(60),
                    calendars: nil
                )
                let inMeeting = store.events(matching: predicate).contains { event in
                    guard !event.isAllDay else { return false }
                    return event.startDate <= now && event.endDate >= now
                }
                cont.resume(returning: inMeeting)
            }
        }
    }
}

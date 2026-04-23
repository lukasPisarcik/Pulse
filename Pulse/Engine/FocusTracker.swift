import Foundation
import AppKit

@MainActor
final class FocusTracker {
    private(set) var activeBundleID: String?
    private var idleThresholdSeconds: TimeInterval = 300

    func startObserving() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        activeBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    func stopObserving() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func appDidActivate(_ note: Notification) {
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        activeBundleID = app?.bundleIdentifier
    }

    var isUserIdle: Bool {
        idleSeconds > idleThresholdSeconds
    }

    var idleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }

    func setIdleThreshold(minutes: Int) {
        idleThresholdSeconds = TimeInterval(max(1, minutes) * 60)
    }
}

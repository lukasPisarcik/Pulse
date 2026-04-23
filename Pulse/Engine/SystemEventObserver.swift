import AppKit

@MainActor
final class SystemEventObserver {
    var onScreenParametersChanged: (() -> Void)?
    var onSystemWillSleep: (() -> Void)?
    var onSystemDidWake: (() -> Void)?
    var onScreenLocked: (() -> Void)?
    var onScreenUnlocked: (() -> Void)?

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParams),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(willSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(didWake),
                       name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(screensSleep),
                       name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(screensWake),
                       name: NSWorkspace.screensDidWakeNotification, object: nil)

        let dc = DistributedNotificationCenter.default()
        dc.addObserver(self, selector: #selector(locked),
                       name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        dc.addObserver(self, selector: #selector(unlocked),
                       name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func screenParams() { onScreenParametersChanged?() }
    @objc private func willSleep()    { onSystemWillSleep?() }
    @objc private func didWake()      { onSystemDidWake?() }
    @objc private func screensSleep() { onSystemWillSleep?() }
    @objc private func screensWake()  { onSystemDidWake?() }
    @objc private func locked()       { onScreenLocked?() }
    @objc private func unlocked()     { onScreenUnlocked?() }
}

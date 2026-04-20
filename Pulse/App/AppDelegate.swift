import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = WellnessEngine()
    let tracker = FocusTracker()
    let calendar = CalendarBridge()
    let store = SettingsStore()
    let notifier = NotificationManager()

    lazy var scheduler: BreakScheduler = BreakScheduler(
        engine: engine,
        tracker: tracker,
        calendar: calendar,
        store: store,
        notifier: notifier
    )

    lazy var notchController = NotchWindowController(
        engine: engine,
        scheduler: scheduler,
        store: store
    )

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        Task {
            await notifier.requestAuthorization()
            await calendar.requestAccess()
        }

        tracker.startObserving()
        scheduler.start()
        notchController.show()

        configureLaunchAtLogin()
        installStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        scheduler.stop()
        tracker.stopObserving()
        notchController.hide()
    }

    // MARK: - Status item (hidden fallback menu)

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "bird", accessibilityDescription: "Pulse")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Take a break now",
                     action: #selector(takeBreakNow),
                     keyEquivalent: "").target = self
        menu.addItem(withTitle: "Snooze 15 min",
                     action: #selector(snoozeNow),
                     keyEquivalent: "").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Settings…",
                     action: #selector(openSettings),
                     keyEquivalent: ",").target = self
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Pulse",
                     action: #selector(quit),
                     keyEquivalent: "q").target = self
        item.menu = menu
        statusItem = item
    }

    @objc private func takeBreakNow() {
        scheduler.recordBreak(kind: .eyeRest)
    }

    @objc private func snoozeNow() {
        scheduler.snooze(minutes: 15)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Launch at login

    private func configureLaunchAtLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if store.launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // silent — not critical
        }
    }
}

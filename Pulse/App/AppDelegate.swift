import AppKit
import SwiftUI
import SwiftData
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
    private var settingsWindow: NSWindow?
    private var modelContainer: ModelContainer?
    private var onboardingController: OnboardingWindowController?
    private var foregroundServicesStarted = false
    private var isCompletingOnboarding = false
    private var isRerunOnboardingActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setUpModelContainer()
        configureLaunchAtLogin()

        if store.hasCompletedOnboarding {
            startForegroundServices()
        } else {
            showOnboarding()
        }
    }

    private func startForegroundServices() {
        guard !foregroundServicesStarted else { return }
        foregroundServicesStarted = true

        notchController.onOpenSettingsRequested = { [weak self] in
            self?.openSettings()
        }
        notchController.onQuitRequested = { [weak self] in
            self?.quit()
        }

        Task {
            let notificationStatus = await notifier.authorizationStatus()
            if notificationStatus == .notDetermined {
                await notifier.requestAuthorization()
            }

            // Keep calendar status fresh for scheduler checks, but do not
            // auto-request at launch. Permission is requested from onboarding.
            calendar.refreshAuthorizationCache()
        }

        tracker.startObserving()
        scheduler.start()
        notchController.show()
        refreshStatusItemVisibility()
    }

    private func showOnboarding() {
        let coordinator = OnboardingCoordinator(
            store: store,
            calendar: calendar,
            notifier: notifier,
            onFinish: { [weak self] in self?.handleOnboardingFinish() },
            onSkipConfirmed: { [weak self] in self?.handleOnboardingFinish() }
        )
        let controller = OnboardingWindowController(coordinator: coordinator)
        onboardingController = controller
        controller.show()
    }

    private func handleOnboardingFinish() {
        guard !isCompletingOnboarding else { return }
        isCompletingOnboarding = true
        store.hasCompletedOnboarding = true
        // Hop off the current event (the Continue button action, or AppKit's
        // windowShouldClose callback) before we start animating the window
        // away. Closing the window synchronously from inside either of those
        // contexts tears down the SwiftUI view tree — including the
        // OnboardingCoordinator that is still publishing — and crashes.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let controller = self.onboardingController else {
                self.finalizeOnboardingHandoff()
                return
            }
            controller.fadeOutAndClose { [weak self] in
                guard let self else { return }
                self.onboardingController = nil
                self.finalizeOnboardingHandoff()
            }
        }
    }

    private func finalizeOnboardingHandoff() {
        if isRerunOnboardingActive {
            resumeForegroundAfterRerunOnboarding()
        } else {
            startForegroundServices()
        }
        isCompletingOnboarding = false
    }

    /// Called from GeneralSettingsView → "Rerun onboarding".
    /// All destructive work is deferred to the next runloop tick so that we
    /// don't tear down the Settings window's SwiftUI hierarchy from inside the
    /// Button action that's still on the stack — that's a reliable way to
    /// crash AppKit/SwiftUI with a use-after-free.
    func restartOnboarding() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if let existing = self.onboardingController {
                existing.close()
                self.onboardingController = nil
            }

            if let window = self.settingsWindow {
                window.delegate = nil
                window.orderOut(nil)
                window.close()
                self.settingsWindow = nil
            }

            if self.foregroundServicesStarted {
                self.pauseForegroundForRerunOnboarding()
            }

            self.store.hasCompletedOnboarding = false
            self.isCompletingOnboarding = false
            self.showOnboarding()
        }
    }

    private func pauseForegroundForRerunOnboarding() {
        guard !isRerunOnboardingActive else { return }
        isRerunOnboardingActive = true

        scheduler.stop()
        tracker.stopObserving()
        notchController.setTemporarilyHidden(true)

        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func resumeForegroundAfterRerunOnboarding() {
        guard isRerunOnboardingActive else { return }
        tracker.startObserving()
        scheduler.start()
        notchController.setTemporarilyHidden(false)
        refreshStatusItemVisibility()
        isRerunOnboardingActive = false
    }

    private func setUpModelContainer() {
        let schema = Schema([BreakRecord.self, SessionRecord.self])
        let storeURL = Self.storeURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)

        if let container = try? ModelContainer(for: schema, configurations: config) {
            modelContainer = container
            scheduler.modelContext = container.mainContext
            return
        }

        // Recovery: the store exists but schema is out of sync (e.g. the
        // "no such table: ZBREAKRECORD" SQLite error). Remove the store and
        // its sidecars, then try once more with a clean slate.
        Self.destroyStore(at: storeURL)
        if let container = try? ModelContainer(for: schema, configurations: config) {
            modelContainer = container
            scheduler.modelContext = container.mainContext
        }
        // Persistence stays disabled if the retry also fails.
    }

    private static func storeURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true))
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        let dir = base.appendingPathComponent("Pulse", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Pulse.store")
    }

    private static func destroyStore(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let sidecar = URL(fileURLWithPath: url.path + suffix)
            try? fm.removeItem(at: sidecar)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        scheduler.stop()
        tracker.stopObserving()
        notchController.hide()
    }

    // MARK: - Status item (right-click menu fallback)

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "bird", accessibilityDescription: "Pulse")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…",
                     action: #selector(openSettings),
                     keyEquivalent: ",").target = self
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Export App Icons to Desktop…",
                     action: #selector(exportIcons),
                     keyEquivalent: "").target = self
        #endif
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
        if settingsWindow == nil {
            let root = SettingsView(onRerunOnboarding: { [weak self] in
                self?.restartOnboarding()
            }, onApplyLaunchAtLogin: { [weak self] in
                self?.configureLaunchAtLogin()
            }, onApplyMenuBarVisibility: { [weak self] in
                self?.refreshStatusItemVisibility()
            }, onDeleteWellnessData: { [weak self] in
                self?.deleteWellnessData()
            })
                .environmentObject(store)
                .environmentObject(engine)
            let hosting = NSHostingController(rootView: root)
            let window = NSWindow(contentViewController: hosting)
            window.styleMask = [.titled, .fullSizeContentView, .closable, .resizable]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            if #available(macOS 11.0, *) {
                window.titlebarSeparatorStyle = .none
            }
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.appearance = NSAppearance(named: .darkAqua)
            window.setContentSize(NSSize(width: 820, height: 580))
            window.isReleasedWhenClosed = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func refreshStatusItemVisibility() {
        if store.showMenuBarIcon {
            if statusItem == nil {
                installStatusItem()
            }
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    #if DEBUG
    @objc private func exportIcons() {
        do {
            let url = try IconGenerator.exportToDesktop()
            NSWorkspace.shared.activateFileViewerSelecting([url])
            let alert = NSAlert()
            alert.messageText = "App icons exported"
            alert.informativeText = "Wrote \(url.lastPathComponent) to your Desktop."
            alert.alertStyle = .informational
            alert.runModal()
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    #endif

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
            // silent
        }
    }

    private func deleteWellnessData() {
        guard let context = modelContainer?.mainContext else { return }
        do {
            let breaks = try context.fetch(FetchDescriptor<BreakRecord>())
            let sessions = try context.fetch(FetchDescriptor<SessionRecord>())
            for record in breaks {
                context.delete(record)
            }
            for record in sessions {
                context.delete(record)
            }
            try context.save()
        } catch {
            // best-effort only
        }
    }
}

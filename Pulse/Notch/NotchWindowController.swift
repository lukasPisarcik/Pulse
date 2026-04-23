import AppKit
import SwiftUI
import Combine

@MainActor
final class NotchWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var hostingView: NotchHostingView<NotchRootView>?
    private let systemEvents = SystemEventObserver()
    private var visibilityHeartbeat: Timer?
    private var appActivationObserver: NSObjectProtocol?
    private var isTemporarilyHidden: Bool = false

    /// Screen the pill is anchored to for the life of the session. Resolved once
    /// at `show()` (prefer a notched screen) and refreshed on display changes.
    /// Held statically so `NotchRootView`'s geometry reads never fall back to
    /// `NSScreen.main`, which shifts to whatever display has keyboard focus and
    /// would otherwise flip us into the plain-pill layout on multi-monitor setups.
    fileprivate static var hostScreen: NSScreen?

    private let engine: WellnessEngine
    private let scheduler: BreakScheduler
    private let store: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    var onOpenSettingsRequested: (() -> Void)?
    var onQuitRequested: (() -> Void)?

    /// Tracks the last observed wellness state so we only auto-expand on
    /// *forward* transitions (flow → heads-up → rest-now). Without this, any
    /// republish (e.g. initial sink) would re-trigger an auto-expand.
    private var lastObservedState: WellnessState?
    private var autoCollapseTask: Task<Void, Never>?
    /// Duration the auto-expanded panel stays visible before folding back to
    /// the pill. Long enough to read the message suggestion, short enough to
    /// not linger once the user has glanced at it.
    private let autoExpandDuration: TimeInterval = 10

    enum Presentation: Equatable {
        case idle
        case hover
        case expanded
    }

    @Published var presentation: Presentation = .idle

    init(engine: WellnessEngine, scheduler: BreakScheduler, store: SettingsStore) {
        self.engine = engine
        self.scheduler = scheduler
        self.store = store
        super.init()
    }

    func show() {
        guard window == nil else { return }
        Self.hostScreen = Self.pickHostScreen()
        let frame = Self.windowFrame(for: Self.hostScreen)
        let win = NotchPanel(contentRect: frame,
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        // Sit just above the system status bar — high enough to render across
        // / outside the hardware notch cutout on notched Macs, but low enough
        // that mouse events route to us reliably. `.screenSaver` is too
        // aggressive: AppKit deprioritises mouse delivery to windows at that
        // level when the owning app is non-active (which we always are; we're
        // a `.accessory` LSUIElement), and clicks/hovers stop firing.
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        win.ignoresMouseEvents = false
        // Without this the panel doesn't dispatch mouseMoved events, which
        // SwiftUI uses (alongside mouseEntered/Exited) to keep `.onHover`
        // state in sync as the cursor slides across the pill.
        win.acceptsMouseMovedEvents = true
        win.isMovable = false
        win.delegate = self

        // Use `NotchHostingView` (not `NSHostingView`) so the SwiftUI gesture
        // recognizers underneath get first-mouse events. The notch panel can
        // never become key (`.nonactivatingPanel` + `canBecomeKey = false`),
        // and a vanilla `NSHostingView` on a non-key window will swallow the
        // first click — which from the user's perspective looks like the
        // notch is completely dead to hover and tap.
        let host = NotchHostingView(rootView: makeRoot())
        host.frame = win.contentView!.bounds
        host.autoresizingMask = [.width, .height]
        win.contentView?.addSubview(host)
        win.contentView?.wantsLayer = true
        hostingView = host

        win.orderFrontRegardless()
        window = win

        observeEngine()
        applyStateStyling(engine.state)
        startSystemObservers()
        startVisibilityHeartbeat()
        observeAppActivation()
    }

    func hide() {
        systemEvents.stop()
        stopVisibilityHeartbeat()
        stopObservingAppActivation()
        autoCollapseTask?.cancel()
        autoCollapseTask = nil
        lastObservedState = nil
        isTemporarilyHidden = false
        window?.orderOut(nil)
        window = nil
        hostingView = nil
        cancellables.removeAll()
    }

    /// Hides/shows the notch window without tearing down controller state.
    /// Used for rerun onboarding to avoid object lifecycle churn.
    func setTemporarilyHidden(_ hidden: Bool) {
        isTemporarilyHidden = hidden
        guard let window else { return }
        if hidden {
            window.orderOut(nil)
        } else {
            ensureVisible()
        }
    }

    /// The panel is at status-window level, but certain macOS flows can still
    /// drop it behind — full-screen Space switches, display sleep/wake,
    /// screen-lock cycles, and long idle windows. A cheap 15s heartbeat
    /// re-asserts the level and orders the window front if it ever slips.
    private func startVisibilityHeartbeat() {
        stopVisibilityHeartbeat()
        visibilityHeartbeat = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.ensureVisible() }
        }
    }

    private func stopVisibilityHeartbeat() {
        visibilityHeartbeat?.invalidate()
        visibilityHeartbeat = nil
    }

    private func observeAppActivation() {
        stopObservingAppActivation()
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.ensureVisible() }
        }
    }

    private func stopObservingAppActivation() {
        if let token = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(token)
            appActivationObserver = nil
        }
    }

    /// Idempotent re-assert. Cheap to call — NSWindow no-ops if already fronted.
    private func ensureVisible() {
        guard !isTemporarilyHidden else { return }
        guard let window else { return }
        let target = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        if window.level != target {
            window.level = target
        }
        // Re-assert ordering on every heartbeat — cheap, and fixes the case
        // where another status-level window landed on top.
        window.orderFrontRegardless()
    }

    /// SwiftUI owns presentation changes now, so the controller just forwards
    /// any programmatic mutations. The window frame never changes.
    private func setPresentation(_ next: Presentation) {
        guard presentation != next else { return }
        presentation = next
        hostingView?.rootView = makeRoot()
    }

    private func makeRoot() -> NotchRootView {
        NotchRootView(
            engine: engine,
            store: store,
            presentationBinding: Binding(
                get: { [weak self] in self?.presentation ?? .idle },
                set: { [weak self] next in
                    guard let self else { return }
                    guard self.presentation != next else { return }
                    // User-driven presentation changes cancel any pending
                    // auto-collapse so a manual expand isn't snapped shut.
                    self.autoCollapseTask?.cancel()
                    self.autoCollapseTask = nil
                    self.presentation = next
                    // The binding source lives on this controller, not in a
                    // SwiftUI-observed model. Re-mount the root immediately so
                    // hover/tap transitions render without waiting for another
                    // controller-driven refresh.
                    self.hostingView?.rootView = self.makeRoot()
                }
            ),
            onTakeBreak: { [weak self] in
                self?.scheduler.recordBreak(kind: .eyeRest)
            },
            onSnooze: { [weak self] in
                self?.scheduler.snooze(minutes: 15)
            },
            onOpenSettings: { [weak self] in
                self?.onOpenSettingsRequested?()
            },
            onQuit: { [weak self] in
                self?.onQuitRequested?()
            }
        )
    }

    private func observeEngine() {
        engine.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyStateStyling(state)
                self?.handleStateTransition(to: state)
            }
            .store(in: &cancellables)
    }

    /// Auto-expands the notch when the user crosses into a more urgent wellness
    /// stage (flow → heads-up → rest-now) so the message suggestion surfaces
    /// without waiting for a hover. Folds back to idle after
    /// `autoExpandDuration` unless the user takes another action.
    private func handleStateTransition(to state: WellnessState) {
        defer { lastObservedState = state }
        guard let previous = lastObservedState else { return }
        guard Self.isEscalation(from: previous, to: state) else { return }

        engine.lastMessage = Self.message(for: state)
        setPresentation(.expanded)
        scheduleAutoCollapse()
    }

    private func scheduleAutoCollapse() {
        autoCollapseTask?.cancel()
        let duration = autoExpandDuration
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                if self.presentation == .expanded {
                    self.setPresentation(.idle)
                }
            }
        }
    }

    private static func isEscalation(from previous: WellnessState, to next: WellnessState) -> Bool {
        priority(next) > priority(previous)
    }

    private static func priority(_ state: WellnessState) -> Int {
        switch state {
        case .flow:    return 0
        case .headsUp: return 1
        case .restNow: return 2
        }
    }

    private static func message(for state: WellnessState) -> String {
        switch state {
        case .flow:    return NotificationTemplates.random(for: PipMessageKind.flowAck)
        case .headsUp: return NotificationTemplates.random(for: PipMessageKind.eyeRest)
        case .restNow: return NotificationTemplates.random(for: PipMessageKind.movement)
        }
    }

    private func startSystemObservers() {
        systemEvents.onScreenParametersChanged = { [weak self] in
            self?.repositionForCurrentScreen()
            self?.ensureVisible()
        }
        systemEvents.onSystemWillSleep = { [weak self] in
            self?.scheduler.pauseForSystemEvent()
        }
        systemEvents.onSystemDidWake = { [weak self] in
            self?.scheduler.resumeFromSystemEvent()
            self?.repositionForCurrentScreen()
            self?.ensureVisible()
        }
        systemEvents.onScreenLocked = { [weak self] in
            self?.scheduler.pauseForSystemEvent()
        }
        systemEvents.onScreenUnlocked = { [weak self] in
            self?.scheduler.resumeFromSystemEvent()
            self?.ensureVisible()
        }
        systemEvents.start()
    }

    private func repositionForCurrentScreen() {
        guard let window else { return }
        // Re-pick in case the notched display was disconnected / reconnected.
        Self.hostScreen = Self.pickHostScreen()
        let frame = Self.windowFrame(for: Self.hostScreen)
        window.setFrame(frame, display: true)
    }

    /// Prefer a screen with a hardware notch; fall back to `NSScreen.main`
    /// (whatever has keyboard focus right now) and finally the first screen.
    /// This is what keeps the pill's design stable across multi-monitor setups.
    private static func pickHostScreen() -> NSScreen? {
        if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notched
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    private func applyStateStyling(_ state: WellnessState) {
        // Glow attaches to the hosting view's pill; currently unused with the
        // fixed-size-window approach, but kept for future visual state cues.
        _ = state
    }

    /// Fixed window frame sized for the largest presentation (`.expanded`).
    /// The pill inside animates smoothly between idle/hover/expanded without
    /// ever resizing the window.
    static func windowFrame(for screen: NSScreen?) -> NSRect {
        guard let screen = screen ?? NSScreen.main else {
            return NSRect(x: 0, y: 0, width: 280, height: 160)
        }
        let geometry = NotchGeometry(screen: screen)
        let size = geometry.windowSize(for: .expanded)
        let screenFrame = screen.frame
        let x = screenFrame.midX - size.width / 2
        let topY: CGFloat = geometry.hasNotch ? screenFrame.maxY : screen.visibleFrame.maxY
        let y = topY - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// Resolves against the pinned `hostScreen` by default so geometry reads from
    /// `NotchRootView` stay stable when keyboard focus moves to another display.
    static func notchGeometry(for screen: NSScreen? = nil) -> NotchGeometry {
        let resolved = screen
            ?? hostScreen
            ?? pickHostScreen()
            ?? NSScreen.screens[0]
        return NotchGeometry(screen: resolved)
    }
}

struct NotchGeometry {
    let hasNotch: Bool
    let notchWidth: CGFloat
    let notchHeight: CGFloat

    /// Visible extension on each side of the hardware cutout.
    /// Sized to fit the idle content (Pip on the left, focus-streak text on the right)
    /// with breathing room — any wider and the pill looks detached from the notch.
    var wingWidth: CGFloat { hasNotch ? 56 : 0 }

    /// Empty margin around the pill inside the window, so the glow / bloom can
    /// bleed onto the menu-bar area without being clipped at the window edge.
    var glowInset: CGFloat { 28 }

    init(screen: NSScreen) {
        let topInset = screen.safeAreaInsets.top
        self.notchHeight = topInset
        if #available(macOS 12.0, *),
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea,
           topInset > 0 {
            self.hasNotch = true
            self.notchWidth = screen.frame.width - left.width - right.width
        } else {
            self.hasNotch = false
            self.notchWidth = 200
        }
    }

    /// Additional height *below* the notch band for hover/expanded presentations.
    func extraHeight(for presentation: NotchWindowController.Presentation) -> CGFloat {
        guard hasNotch else {
            switch presentation {
            case .idle:     return 28
            case .hover:    return 40
            case .expanded: return 110
            }
        }
        switch presentation {
        case .idle:     return 0
        case .hover:    return 30
        case .expanded: return 110
        }
    }

    /// Size of the visible pill for a given presentation (no glow padding).
    func pillSize(for presentation: NotchWindowController.Presentation) -> CGSize {
        let extra = extraHeight(for: presentation)
        if hasNotch {
            let width = notchWidth + 2 * wingWidth
            return CGSize(width: width, height: notchHeight + extra)
        }
        switch presentation {
        case .idle:     return CGSize(width: 200, height: extra)
        case .hover:    return CGSize(width: 300, height: extra)
        case .expanded: return CGSize(width: 360, height: extra)
        }
    }

    /// Full NSWindow size, including glow inset so the bloom can spill outside the pill.
    func windowSize(for presentation: NotchWindowController.Presentation) -> CGSize {
        let pill = pillSize(for: presentation)
        return CGSize(
            width: pill.width + 2 * glowInset,
            height: pill.height + glowInset
        )
    }
}

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

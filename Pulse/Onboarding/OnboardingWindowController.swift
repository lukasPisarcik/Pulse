import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let coordinator: OnboardingCoordinator
    private var isProgrammaticClose = false

    init(coordinator: OnboardingCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    func show() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .fullSizeContentView, .closable],
            backing: .buffered,
            defer: false
        )
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = true
        // Default is true for NSWindow.init(contentRect:…). With ARC + the
        // implicit `_NSWindowTransformAnimation` that `win.animator()` spins
        // up during the fade-out, letting AppKit auto-release the window on
        // close races the still-in-flight CA transaction and crashes inside
        // `_NSWindowTransformAnimation dealloc`. We own the lifetime here.
        win.isReleasedWhenClosed = false
        win.center()
        win.delegate = self
        win.standardWindowButton(.miniaturizeButton)?.isHidden = true
        win.standardWindowButton(.zoomButton)?.isHidden = true

        let root = OnboardingContainerView(coordinator: coordinator)
        let host = NSHostingController(rootView: root)
        host.view.frame = NSRect(x: 0, y: 0, width: 720, height: 560)
        win.contentViewController = host

        win.alphaValue = 0
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        fadeIn(win)

        window = win
    }

    func fadeOutAndClose(_ completion: @escaping () -> Void) {
        guard let win = window else { completion(); return }
        // Detach the delegate up-front so the fade animation can't re-enter
        // windowShouldClose mid-animation if the user hits ⌘W.
        isProgrammaticClose = true
        win.delegate = nil
        // Drop our handle eagerly so a re-entrant call (or a stale caller)
        // can't try to drive the window again while the fade is still in
        // flight.
        self.window = nil

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            win.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            // Hop one runloop turn so we settle *after* the CoreAnimation
            // transaction that owns `_NSWindowTransformAnimation` has had a
            // chance to commit — tearing the window down inside that commit
            // crashes inside the animation's dealloc.
            Task { @MainActor in
                win.orderOut(nil)
                self?.isProgrammaticClose = false
                completion()
            }
        })
    }

    func close() {
        guard let win = window else { return }
        isProgrammaticClose = true
        win.delegate = nil
        win.orderOut(nil)
        window = nil
        isProgrammaticClose = false
    }

    private func fadeIn(_ win: NSWindow) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            win.animator().alphaValue = 1
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !isProgrammaticClose else { return true }
        // Closing the window mid-flow is treated as a skip-with-confirmation
        // trigger upstream; AppDelegate reopens onboarding if the user hasn't
        // confirmed completion. Defer the coordinator callback so we don't
        // re-enter NSWindow's close machinery from inside this delegate
        // callback (which can crash AppKit).
        Task { @MainActor [coordinator] in
            coordinator.confirmSkip()
        }
        return false
    }
}

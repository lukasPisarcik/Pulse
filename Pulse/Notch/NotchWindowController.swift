import AppKit
import SwiftUI
import Combine

@MainActor
final class NotchWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var hostingView: NSHostingView<NotchRootView>?
    private let glow = NotchGlowLayer()

    private let engine: WellnessEngine
    private let scheduler: BreakScheduler
    private let store: SettingsStore
    private var cancellables = Set<AnyCancellable>()

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
        let frame = Self.notchFrame(for: NSScreen.main, presentation: .idle)
        let win = NotchPanel(contentRect: frame,
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        win.level = .statusBar
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        win.ignoresMouseEvents = false
        win.isMovable = false
        win.delegate = self

        let root = NotchRootView(
            engine: engine,
            store: store,
            presentationBinding: Binding(
                get: { [weak self] in self?.presentation ?? .idle },
                set: { [weak self] in self?.setPresentation($0) }
            ),
            onTakeBreak: { [weak self] in
                self?.scheduler.recordBreak(kind: .eyeRest)
                self?.setPresentation(.idle)
            },
            onSnooze: { [weak self] in
                self?.scheduler.snooze(minutes: 15)
                self?.setPresentation(.idle)
            }
        )
        let host = NSHostingView(rootView: root)
        host.frame = win.contentView!.bounds
        host.autoresizingMask = [.width, .height]
        win.contentView?.addSubview(host)
        win.contentView?.wantsLayer = true
        hostingView = host

        if let layer = win.contentView?.layer {
            glow.attach(to: layer, frame: layer.bounds.insetBy(dx: 4, dy: 4))
        }

        win.orderFrontRegardless()
        window = win

        observeEngine()
        applyStateStyling(engine.state)
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        hostingView = nil
        cancellables.removeAll()
    }

    private func setPresentation(_ next: Presentation) {
        guard presentation != next else { return }
        presentation = next

        let frame = Self.notchFrame(for: NSScreen.main, presentation: next)
        window?.animator().setFrame(frame, display: true, animate: true)

        if let layer = window?.contentView?.layer {
            glow.updateFrame(layer.bounds.insetBy(dx: 4, dy: 4))
        }

        hostingView?.rootView = NotchRootView(
            engine: engine,
            store: store,
            presentationBinding: Binding(
                get: { [weak self] in self?.presentation ?? .idle },
                set: { [weak self] in self?.setPresentation($0) }
            ),
            onTakeBreak: { [weak self] in
                self?.scheduler.recordBreak(kind: .eyeRest)
                self?.setPresentation(.idle)
            },
            onSnooze: { [weak self] in
                self?.scheduler.snooze(minutes: 15)
                self?.setPresentation(.idle)
            }
        )
    }

    private func observeEngine() {
        engine.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyStateStyling(state)
            }
            .store(in: &cancellables)
    }

    private func applyStateStyling(_ state: WellnessState) {
        let color: NSColor
        switch state {
        case .flow:    color = .pulseGreen
        case .headsUp: color = .pulseAmber
        case .restNow: color = .pulseRed
        }
        glow.setState(color: color, pulseDuration: state.pulseDuration)
    }

    static func notchFrame(for screen: NSScreen?, presentation: Presentation) -> NSRect {
        guard let screen = screen ?? NSScreen.main else {
            return NSRect(x: 0, y: 0, width: 280, height: 32)
        }
        let (width, height): (CGFloat, CGFloat)
        switch presentation {
        case .idle:     (width, height) = (250, 38)
        case .hover:    (width, height) = (300, 44)
        case .expanded: (width, height) = (360, 110)
        }
        let screenFrame = screen.frame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}

final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

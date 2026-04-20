import SwiftUI

struct NotchRootView: View {
    @ObservedObject var engine: WellnessEngine
    @ObservedObject var store: SettingsStore
    @Binding var presentation: NotchWindowController.Presentation
    let onTakeBreak: () -> Void
    let onSnooze: () -> Void

    init(
        engine: WellnessEngine,
        store: SettingsStore,
        presentationBinding: Binding<NotchWindowController.Presentation>,
        onTakeBreak: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        self.engine = engine
        self.store = store
        self._presentation = presentationBinding
        self.onTakeBreak = onTakeBreak
        self.onSnooze = onSnooze
    }

    var body: some View {
        Group {
            switch presentation {
            case .idle:
                NotchIdleView(engine: engine, store: store)
                    .onHover { hovering in
                        if hovering { presentation = .hover }
                    }
                    .onTapGesture { presentation = .expanded }
            case .hover:
                NotchHoverView(engine: engine)
                    .onHover { hovering in
                        if !hovering { presentation = .idle }
                    }
                    .onTapGesture { presentation = .expanded }
            case .expanded:
                NotchExpandedView(
                    engine: engine,
                    onTakeBreak: onTakeBreak,
                    onSnooze: onSnooze,
                    onClose: { presentation = .idle }
                )
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: presentation)
    }
}

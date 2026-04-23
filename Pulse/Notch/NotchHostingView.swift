import AppKit
import SwiftUI

/// `NSHostingView` subclass that lets SwiftUI gestures fire inside a
/// non-activating notch panel.
///
/// The notch sits in an `NSPanel` with `.nonactivatingPanel` styleMask and
/// `canBecomeKey == false` — so the window is never key. AppKit's default
/// behaviour for clicks in a non-key window is to swallow the first event
/// (it would normally just bring the window to key) and only forward
/// subsequent ones. That makes SwiftUI's `.onTapGesture` look completely
/// dead, and starves `.onHover` of the mouse-entered events it depends on
/// because the hosting view never gets a chance to install / refresh its
/// tracking areas with a "live" first responder underneath it.
///
/// Returning `true` from `acceptsFirstMouse(for:)` tells AppKit to deliver
/// every mouse event straight to this view regardless of key state, which
/// is exactly what we want for an ambient menu-bar pill.
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    required init(rootView: Content) {
        super.init(rootView: rootView)
        wantsLayer = true
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

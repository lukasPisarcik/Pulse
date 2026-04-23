import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Placeholder scene required by `App`. The Settings window is managed
    // directly in AppKit (see `AppDelegate.openSettings`) because the SwiftUI
    // `Settings { }` scene's `showSettingsWindow:` selector prints a
    // "Please use SettingsLink" runtime warning and doesn't reliably open
    // for `.accessory` apps on macOS 14+.
    var body: some Scene {
        Settings { EmptyView() }
    }
}

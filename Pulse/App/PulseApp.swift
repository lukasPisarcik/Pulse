import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.store)
                .environmentObject(appDelegate.engine)
        }
        .modelContainer(for: [BreakRecord.self, SessionRecord.self]) { result in
            switch result {
            case .success(let container):
                Task { @MainActor in
                    appDelegate.scheduler.modelContext = container.mainContext
                }
            case .failure:
                break
            }
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: WellnessEngine

    @State private var selection: SettingsPage = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selection) { page in
                Label(page.title, systemImage: page.symbol)
                    .tag(page)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            detailView
                .frame(minWidth: 420, minHeight: 460)
        }
        .frame(minWidth: 640, minHeight: 460)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .general:  GeneralSettingsView()
        case .schedule: ScheduleSettingsView()
        case .breaks:   BreaksSettingsView()
        case .notch:    NotchSettingsView()
        case .pip:      PipSettingsView()
        case .privacy:  PrivacySettingsView()
        }
    }
}

enum SettingsPage: String, CaseIterable, Identifiable {
    case general, schedule, breaks, notch, pip, privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:  return "General"
        case .schedule: return "Schedule"
        case .breaks:   return "Breaks"
        case .notch:    return "Notch"
        case .pip:      return "Pip"
        case .privacy:  return "Privacy"
        }
    }

    var symbol: String {
        switch self {
        case .general:  return "gear"
        case .schedule: return "calendar"
        case .breaks:   return "timer"
        case .notch:    return "rectangle.topthird.inset.filled"
        case .pip:      return "bird"
        case .privacy:  return "lock.shield"
        }
    }
}

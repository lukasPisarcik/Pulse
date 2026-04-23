import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var engine: WellnessEngine

    @State private var selection: SettingsPage = .general
    let onRerunOnboarding: () -> Void
    let onApplyLaunchAtLogin: () -> Void
    let onApplyMenuBarVisibility: () -> Void
    let onDeleteWellnessData: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blending: .behindWindow)
            LinearGradient(
                colors: [Color.pulseNavy.opacity(0.62), Color.pulseDark.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color.pulsePurple.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .overlay {
                    HStack(spacing: 0) {
                        sidebar
                            .frame(width: 210)

                        Divider()
                            .overlay(Color.white.opacity(0.08))

                        detailView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(14)
                    }
                }
                .padding(.top, 22)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .frame(minWidth: 760, minHeight: 540)
        .ignoresSafeArea()
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pulse Settings")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(Color.white.opacity(0.65))
                .padding(.horizontal, 14)
                .padding(.top, 20)

            ForEach(SettingsPage.allCases) { page in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = page
                    }
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(page.iconColor.opacity(0.18))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: page.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(page.iconColor)
                            )
                        Text(page.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(selection == page ? 0.95 : 0.75))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selection == page ? Color.white.opacity(0.09) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .padding(.bottom, 12)
    }

    private var detailContainer: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.035))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private var detailView: some View {
        detailContainer.overlay {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(selection.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .tracking(0.3)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 4)

                pageContent
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(.bottom, 8)
        }
        .animation(.easeInOut(duration: 0.2), value: selection)
    }

    @ViewBuilder
    private var pageContent: some View {
        switch selection {
        case .general:
            GeneralSettingsView(
                onRerunOnboarding: onRerunOnboarding,
                onApplyLaunchAtLogin: onApplyLaunchAtLogin,
                onApplyMenuBarVisibility: onApplyMenuBarVisibility
            )
        case .schedule:
            ScheduleSettingsView()
        case .breaks:
            BreaksSettingsView()
        case .notch:
            NotchSettingsView()
        case .pip:
            PipSettingsView()
        case .privacy:
            PrivacySettingsView(onDeleteWellnessData: onDeleteWellnessData)
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

    var iconColor: Color {
        switch self {
        case .general:  return .pulsePurple
        case .schedule: return .pulseBlue
        case .breaks:   return .pulseAmber
        case .notch:    return .pulseGreen
        case .pip:      return .pulsePurple
        case .privacy:  return .pulseRed
        }
    }
}

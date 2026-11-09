import SwiftUI
import AppKit

/// The sections in the Settings sidebar.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case downloads = "Downloads"
    case cleanup = "Desktop & Cleanup"
    case widget = "Widget"
    case dock = "Dock"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .downloads: return "arrow.down.circle"
        case .cleanup: return "sparkles"
        case .widget: return "square.grid.2x2"
        case .dock: return "dock.rectangle"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var focus: FocusManager
    @Environment(\.openWindow) private var openWindow

    @State private var section: SettingsSection? = .downloads
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var loginMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            List(SettingsSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .frame(width: 190)

            Divider()

            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 720, height: 500)
    }

    @ViewBuilder
    private var detail: some View {
        switch section ?? .general {
        case .general: general
        case .downloads: downloads
        case .cleanup: cleanup
        case .widget: widget
        case .dock: dock
        }
    }

    // MARK: - General

    private var general: some View {
        Form {
            Section {
                Toggle("Launch Seder at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        do {
                            try LoginItem.set(newValue)
                            loginMessage = LoginItem.needsApproval
                                ? "Approve Seder in System Settings → General → Login Items."
                                : nil
                        } catch {
                            loginMessage = error.localizedDescription
                        }
                        launchAtLogin = LoginItem.isEnabled
                    }
                ))

                if let loginMessage {
                    Text(loginMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } footer: {
                Text("Works best when Seder is installed in the Applications folder.")
            }

            Section("Statistics") {
                LabeledContent("Files sorted", value: "\(appState.sortedCount)")
                Button("Reset Counter") {
                    appState.sortedCount = 0
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Downloads

    private var downloads: some View {
        Form {
            Section {
                Toggle("Sort new downloads automatically", isOn: Binding(
                    get: { appState.isWatching },
                    set: { isOn in
                        if isOn {
                            appState.startWatching()
                        } else {
                            appState.stopWatching()
                        }
                    }
                ))
            } footer: {
                Text("Watches ~/Downloads and moves each file once it has finished downloading.")
            }

            Section("Existing files") {
                HStack {
                    Text(appState.lastMessage.isEmpty
                         ? "Sort everything that's already in Downloads."
                         : appState.lastMessage)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Undo") {
                        appState.undoLastSort()
                    }
                    .disabled(!appState.canUndo)
                    Button("Sort Now") {
                        appState.sortNow()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Categories") {
                ForEach(FileCategory.allCases, id: \.self) { category in
                    LabeledContent(category.folderName) {
                        Text(category == .other
                             ? "everything else"
                             : category.extensions.sorted().joined(separator: ", "))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Desktop & Cleanup

    private var cleanup: some View {
        Form {
            Section("Desktop") {
                HStack {
                    Text("Sort Desktop files into category folders")
                    Spacer()
                    Button("Clean Up Desktop") {
                        appState.cleanUpDesktop()
                    }
                }
                Toggle("Hide Desktop icons", isOn: $appState.hideDesktopIcons)
            }

            Section("Unused files") {
                HStack {
                    Text("Find files you haven't opened in a while")
                    Spacer()
                    Button("Open Unused Files…") {
                        openWindow(id: "unused-files")
                        NSApp.activate()
                    }
                }
            }

            Section("Idle apps") {
                Picker("Consider an app idle after", selection: $focus.idleAfterMinutes) {
                    Text("1 minute").tag(1)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                }
                LabeledContent("Idle right now", value: "\(focus.idleApps.count)")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Widget

    private var widget: some View {
        Form {
            Section {
                Toggle("Show widget", isOn: $appState.showWidget)

                Toggle("Keep widget on top of other windows", isOn: $appState.widgetOnTop)
                    .disabled(!appState.showWidget)

                Picker("Size", selection: $appState.widgetSize) {
                    ForEach(WidgetSize.allCases) { size in
                        Text(size.title).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!appState.showWidget)
            } footer: {
                Text("Drag the widget by its title row or any empty area. Its position is remembered.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Dock

    private var dock: some View {
        Form {
            Section {
                Toggle("Show only open apps", isOn: $appState.dockOnlyOpenApps)
                Toggle("Show recent apps", isOn: $appState.dockShowRecents)
                Toggle("Auto-hide the Dock", isOn: $appState.dockAutoHide)
            } footer: {
                Text("The Dock restarts for a moment after each change.")
            }

            Section {
                HStack {
                    Text(appState.hasDockBackup
                         ? "Your original Dock settings are saved."
                         : "No changes made yet.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Restore Original Dock") {
                        appState.restoreDock()
                    }
                    .disabled(!appState.hasDockBackup)
                }
            }
        }
        .formStyle(.grouped)
    }
}

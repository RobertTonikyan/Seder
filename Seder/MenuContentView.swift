import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var focus: FocusManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(statusText)

        if !appState.lastMessage.isEmpty {
            Text(appState.lastMessage)
        }

        Divider()

        // MARK: Downloads

        Button("Sort Downloads Now") {
            appState.sortNow()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])

        Toggle("Auto-Sort New Downloads", isOn: Binding(
            get: { appState.isWatching },
            set: { isOn in
                if isOn {
                    appState.startWatching()
                } else {
                    appState.stopWatching()
                }
            }
        ))

        Button("Undo Last Sort") {
            appState.undoLastSort()
        }
        .keyboardShortcut("z", modifiers: .command)
        .disabled(!appState.canUndo)

        Divider()

        // MARK: Desktop

        Button("Clean Up Desktop") {
            appState.cleanUpDesktop()
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])

        Toggle("Hide Desktop Icons", isOn: $appState.hideDesktopIcons)

        Button("Unused Files…") {
            openWindow(id: "unused-files")
            NSApp.activate()
        }

        Divider()

        // MARK: Focus

        Button("Focus Mode") {
            focus.focus()
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])

        Button("Show All Apps") {
            focus.showAll()
        }

        Menu("Idle Apps (\(focus.idleApps.count))") {
            if focus.idleApps.isEmpty {
                Text("No idle apps")
            }

            ForEach(focus.idleApps) { idle in
                Button("Quit \(idle.name) · idle \(idle.idleMinutes) min") {
                    focus.quit(idle)
                }
            }

            Divider()

            Button("Quit All Idle Apps") {
                focus.quitAllIdle()
            }
            .disabled(focus.idleApps.isEmpty)

            Picker("Idle After", selection: $focus.idleAfterMinutes) {
                Text("1 minute").tag(1)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
                Text("2 hours").tag(120)
            }
        }

        Divider()

        // MARK: Widget

        Toggle("Show Widget", isOn: $appState.showWidget)

        Toggle("Keep Widget on Top", isOn: $appState.widgetOnTop)
            .disabled(!appState.showWidget)

        Picker("Widget Size", selection: $appState.widgetSize) {
            ForEach(WidgetSize.allCases) { size in
                Text(size.title).tag(size)
            }
        }
        .disabled(!appState.showWidget)

        // MARK: Dock

        Menu("Dock") {
            Toggle("Show Only Open Apps", isOn: $appState.dockOnlyOpenApps)
            Toggle("Show Recent Apps", isOn: $appState.dockShowRecents)
            Toggle("Auto-Hide Dock", isOn: $appState.dockAutoHide)

            Divider()

            Button("Restore Original Dock") {
                appState.restoreDock()
            }
            .disabled(!appState.hasDockBackup)
        }

        Divider()

        Button("Settings…") {
            openSettings()
            NSApp.activate()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit Seder") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var statusText: String {
        appState.isWatching
            ? "Watching Downloads · \(appState.sortedCount) files sorted"
            : "Not watching Downloads · \(appState.sortedCount) files sorted"
    }
}

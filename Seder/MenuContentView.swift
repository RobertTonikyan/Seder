import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(statusText)

        if !appState.lastMessage.isEmpty {
            Text(appState.lastMessage)
        }

        Divider()

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

        Button("Clean Up Desktop") { }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(true) // step 6

        Button("Focus Mode") { }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(true) // step 7

        Toggle("Show Widget", isOn: $appState.showWidget)

        Button("Unused Files…") { }
            .disabled(true) // step 6

        Button("Dock Settings…") { }
            .disabled(true) // step 7

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

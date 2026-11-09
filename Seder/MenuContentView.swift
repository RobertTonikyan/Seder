import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(statusText)

        Divider()

        Button("Sort Downloads Now") { }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(true) // step 5

        Button("Clean Up Desktop") { }
            .keyboardShortcut("d", modifiers: [.command, .shift])
            .disabled(true) // step 7

        Button("Focus Mode") { }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(true) // step 8

        Toggle("Show Widget", isOn: $appState.showWidget)

        Divider()

        Button("Unused Files…") { }
            .disabled(true) // step 7

        Button("Dock Settings…") { }
            .disabled(true) // step 8

        Button("Undo Last Sort") { }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!appState.canUndo)

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
            : "Not watching Downloads"
    }
}

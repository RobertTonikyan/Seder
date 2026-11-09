import SwiftUI

@main
struct SederApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Seder", systemImage: "square.stack.3d.up") {
            MenuContentView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)

        Window("Unused Files", id: "unused-files") {
            UnusedFilesView()
        }
        .defaultSize(width: 760, height: 480)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

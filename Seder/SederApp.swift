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

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

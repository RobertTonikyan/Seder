import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            placeholder("General settings")
                .tabItem { Label("General", systemImage: "gearshape") }

            placeholder("Downloads settings")
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }

            placeholder("Desktop & Cleanup settings")
                .tabItem { Label("Cleanup", systemImage: "sparkles") }

            placeholder("Widget settings")
                .tabItem { Label("Widget", systemImage: "square.grid.2x2") }

            placeholder("Dock settings")
                .tabItem { Label("Dock", systemImage: "dock.rectangle") }
        }
        .frame(width: 560, height: 380)
    }

    private func placeholder(_ title: String) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Text("Coming soon").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

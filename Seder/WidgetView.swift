import SwiftUI

struct WidgetView: View {
    @ObservedObject var model: RunningAppsModel
    @ObservedObject var settings: WidgetSettings
    let onSizeChange: (CGSize) -> Void

    private var scale: CGFloat { settings.size.scale }

    var body: some View {
        VStack(alignment: .leading, spacing: 14 * scale) {
            header

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(64 * scale), spacing: 10 * scale), count: 5),
                alignment: .leading,
                spacing: 14 * scale
            ) {
                ForEach(model.apps) { app in
                    AppTile(
                        app: app,
                        scale: scale,
                        onOpen: { model.open(app) },
                        onQuit: { model.quit(app) },
                        onForceQuit: { model.quit(app, force: true) }
                    )
                }
            }
        }
        .frame(width: 360 * scale, alignment: .leading)
        .padding(18 * scale)
        .background(WindowDragHandle())
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24 * scale, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .strokeBorder(.white.opacity(0.2))
        )
        .environment(\.colorScheme, .dark)
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            onSizeChange(newSize)
        }
    }

    /// Title row. The whole row is a drag handle.
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8 * scale) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11 * scale, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Running apps")
                .font(.system(size: 15 * scale, weight: .semibold))
            Spacer()
            Text("\(model.apps.count)")
                .font(.system(size: 30 * scale, weight: .bold))
        }
        .overlay(WindowDragHandle())
        .help("Drag to move")
    }
}

/// One app icon with its name. Hover shows a red ✕ to quit.
struct AppTile: View {
    let app: RunningApp
    let scale: CGFloat
    let onOpen: () -> Void
    let onQuit: () -> Void
    let onForceQuit: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 6 * scale) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 48 * scale, height: 48 * scale)
                Text(app.name)
                    .font(.system(size: 11 * scale))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 64 * scale)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.name)
        .overlay(alignment: .topTrailing) {
            if isHovering && app.canQuit {
                Button(action: onQuit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9 * scale, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20 * scale, height: 20 * scale)
                        .background(Circle().fill(.red))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit \(app.name)")
                .offset(x: -2 * scale, y: -6 * scale)
            }
        }
        .onHover { isHovering = $0 }
        .contextMenu {
            if app.canQuit {
                Button("Quit \(app.name)", action: onQuit)
                Button("Force Quit \(app.name)", action: onForceQuit)
            }
        }
    }
}

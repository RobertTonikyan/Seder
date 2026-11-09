import AppKit
import SwiftUI
import Combine

/// The sizes you can pick for the widget.
enum WidgetSize: String, CaseIterable, Identifiable {
    case small, medium, large, extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var scale: CGFloat {
        switch self {
        case .small: return 0.75
        case .medium: return 1.0
        case .large: return 1.25
        case .extraLarge: return 1.5
        }
    }
}

/// Settings the widget view reacts to.
@MainActor
final class WidgetSettings: ObservableObject {
    @Published var size: WidgetSize = .medium
}

/// Owns the floating widget window: show/hide, level, size and position.
@MainActor
final class WidgetController: NSObject, NSWindowDelegate {
    private let model = RunningAppsModel()
    private let settings = WidgetSettings()
    private var panel: NSPanel?

    var isOnTop = false {
        didSet { panel?.level = level }
    }

    var size: WidgetSize {
        get { settings.size }
        set { settings.size = newValue }
    }

    /// Desktop level = behind normal windows, like a real widget.
    private var level: NSWindow.Level {
        isOnTop
            ? .floating
            : NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    // MARK: - Window

    private func makePanel() -> NSPanel {
        let view = WidgetView(model: model, settings: settings) { [weak self] newSize in
            self?.resize(to: newSize)
        }
        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = []

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 396, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.acceptsMouseMovedEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.level = level
        panel.delegate = self

        panel.setFrameTopLeftPoint(savedTopLeft() ?? defaultTopLeft())
        return panel
    }

    /// Called by the view whenever its size changes (more apps, other size setting).
    /// Keeps the top-left corner in place, so the widget grows downward.
    private func resize(to newSize: CGSize) {
        guard let panel, newSize.width > 0, newSize.height > 0 else { return }

        let topLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
        panel.setContentSize(newSize)
        panel.setFrameTopLeftPoint(topLeft)
    }

    // MARK: - Position

    func windowDidMove(_ notification: Notification) {
        savePosition()
    }

    private func savePosition() {
        guard let panel else { return }
        UserDefaults.standard.set(Double(panel.frame.minX), forKey: "widgetLeft")
        UserDefaults.standard.set(Double(panel.frame.maxY), forKey: "widgetTop")
    }

    private func savedTopLeft() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "widgetLeft") != nil,
              defaults.object(forKey: "widgetTop") != nil else { return nil }

        let point = NSPoint(
            x: defaults.double(forKey: "widgetLeft"),
            y: defaults.double(forKey: "widgetTop")
        )

        // Ignore the saved spot if it's not on any connected screen anymore.
        let isOnScreen = NSScreen.screens.contains { screen in
            screen.frame.insetBy(dx: -2, dy: -2).contains(point)
        }
        return isOnScreen ? point : nil
    }

    private func defaultTopLeft() -> NSPoint {
        let visible = NSScreen.main?.visibleFrame ?? .zero
        return NSPoint(x: visible.minX + 40, y: visible.maxY - 40)
    }
}

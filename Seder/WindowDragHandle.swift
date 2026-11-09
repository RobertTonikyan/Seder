import SwiftUI
import AppKit

/// An invisible area that moves its window when you drag it.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        override var mouseDownCanMoveWindow: Bool { true }

        // Work on the very first click, even when Seder isn't the active app.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}

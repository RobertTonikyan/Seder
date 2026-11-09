import AppKit
import Combine

/// One open app, as shown in the widget.
struct RunningApp: Identifiable, Equatable {
    let id: pid_t
    let name: String
    let icon: NSImage
    let bundleID: String?
    let app: NSRunningApplication

    /// Finder can't be quit, so the widget hides its ✕.
    var canQuit: Bool { bundleID != "com.apple.finder" }

    static func == (lhs: RunningApp, rhs: RunningApp) -> Bool {
        lhs.id == rhs.id
    }
}

/// Keeps an up-to-date list of the apps that are open right now.
@MainActor
final class RunningAppsModel: ObservableObject {
    @Published private(set) var apps: [RunningApp] = []

    /// Apps we asked to quit. Hidden right away so the widget feels instant.
    private var quittingIDs: Set<pid_t> = []
    private var task: Task<Void, Never>?

    init() {
        refresh()
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    func refresh() {
        let ownPID = ProcessInfo.processInfo.processIdentifier

        let current = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular
                    && app.processIdentifier != ownPID
                    && !app.isTerminated
                    && !quittingIDs.contains(app.processIdentifier)
            }
            .map { app in
                RunningApp(
                    id: app.processIdentifier,
                    name: app.localizedName ?? "App",
                    icon: app.icon ?? NSImage(),
                    bundleID: app.bundleIdentifier,
                    app: app
                )
            }

        // Only update when something changed, so the widget doesn't redraw every second.
        if current != apps {
            apps = current
        }
    }

    /// Brings the app to the front.
    func open(_ app: RunningApp) {
        if let url = app.app.bundleURL {
            NSWorkspace.shared.openApplication(
                at: url,
                configuration: NSWorkspace.OpenConfiguration(),
                completionHandler: nil
            )
        } else {
            app.app.activate(options: [])
        }
    }

    /// Asks the app to quit (or forces it). The tile disappears immediately.
    /// If the app is still running after 4 seconds, it's probably waiting for
    /// a "Save changes?" dialog, so we bring it to the front.
    func quit(_ app: RunningApp, force: Bool = false) {
        guard app.canQuit else { return }

        if force {
            _ = app.app.forceTerminate()
        } else {
            _ = app.app.terminate()
        }

        quittingIDs.insert(app.id)
        refresh()

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard let self else { return }

            self.quittingIDs.remove(app.id)
            if !app.app.isTerminated {
                self.open(app)
            }
            self.refresh()
        }
    }
}

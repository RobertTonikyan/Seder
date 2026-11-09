import AppKit
import Combine

/// An app that hasn't been in front for a while.
struct IdleApp: Identifiable, Equatable {
    let id: pid_t
    let name: String
    let idleMinutes: Int
    let app: NSRunningApplication

    static func == (lhs: IdleApp, rhs: IdleApp) -> Bool {
        lhs.id == rhs.id && lhs.idleMinutes == rhs.idleMinutes
    }
}

/// Focus Mode (hide other apps) and tracking of idle apps.
@MainActor
final class FocusManager: ObservableObject {
    @Published private(set) var idleApps: [IdleApp] = []

    @Published var idleAfterMinutes: Int {
        didSet {
            UserDefaults.standard.set(idleAfterMinutes, forKey: "idleAfterMinutes")
            tick()
        }
    }

    private var lastActive: [pid_t: Date] = [:]
    private let startedAt = Date()
    private var task: Task<Void, Never>?

    init() {
        let saved = UserDefaults.standard.integer(forKey: "idleAfterMinutes")
        idleAfterMinutes = saved > 0 ? saved : 30

        tick()
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                self.tick()
            }
        }
    }

    // MARK: - Focus Mode

    /// Hides every app except the one in front.
    func focus() {
        let front = NSWorkspace.shared.frontmostApplication?.processIdentifier
        for app in regularApps() where app.processIdentifier != front {
            app.hide()
        }
    }

    /// Un-hides every app.
    func showAll() {
        for app in regularApps() {
            app.unhide()
        }
    }

    // MARK: - Idle apps

    func quit(_ idle: IdleApp) {
        idle.app.terminate()
        idleApps.removeAll { $0.id == idle.id }
    }

    func quitAllIdle() {
        for idle in idleApps {
            idle.app.terminate()
        }
        idleApps = []
    }

    // MARK: - Private

    /// Normal apps (with a Dock icon), not Seder itself.
    private func regularApps() -> [NSRunningApplication] {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != ownPID && !$0.isTerminated
        }
    }

    private func tick() {
        let now = Date()

        if let front = NSWorkspace.shared.frontmostApplication {
            lastActive[front.processIdentifier] = now
        }

        let running = regularApps()
        let alive = Set(running.map(\.processIdentifier))
        lastActive = lastActive.filter { alive.contains($0.key) }

        let cutoff = now.addingTimeInterval(-Double(idleAfterMinutes) * 60)

        let current = running.compactMap { app -> IdleApp? in
            guard app.bundleIdentifier != "com.apple.finder" else { return nil }

            let last = lastActive[app.processIdentifier] ?? startedAt
            guard last < cutoff else { return nil }

            return IdleApp(
                id: app.processIdentifier,
                name: app.localizedName ?? "App",
                idleMinutes: Int(now.timeIntervalSince(last) / 60),
                app: app
            )
        }
        .sorted { $0.idleMinutes > $1.idleMinutes }

        if current != idleApps {
            idleApps = current
        }
    }
}

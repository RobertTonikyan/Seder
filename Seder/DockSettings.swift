import Foundation

/// Reads and changes Dock settings, with a backup of the originals.
enum DockSettings {
    static let onlyOpenApps = "static-only"
    static let showRecents = "show-recents"
    static let autoHide = "autohide"

    private static let keys = [onlyOpenApps, showRecents, autoHide]
    private static let backupKey = "dockBackup"

    /// Current value of a Dock setting.
    static func bool(_ key: String, default defaultValue: Bool) -> Bool {
        let dock = UserDefaults(suiteName: "com.apple.dock")
        return dock?.object(forKey: key) as? Bool ?? defaultValue
    }

    static var hasBackup: Bool {
        UserDefaults.standard.dictionary(forKey: backupKey) != nil
    }

    /// Changes one setting and restarts the Dock.
    /// The first change saves a backup of the original settings.
    static func set(_ key: String, _ value: Bool) {
        backupIfNeeded()
        run("/usr/bin/defaults", ["write", "com.apple.dock", key, "-bool", value ? "true" : "false"])
        run("/usr/bin/killall", ["Dock"])
    }

    /// Puts back the settings from before Seder changed anything.
    static func restoreOriginal() {
        guard let backup = UserDefaults.standard.dictionary(forKey: backupKey) else { return }

        for key in keys {
            if let value = backup[key] as? Bool {
                run("/usr/bin/defaults", ["write", "com.apple.dock", key, "-bool", value ? "true" : "false"])
            } else {
                // The setting didn't exist before → remove it, so macOS uses its default.
                run("/usr/bin/defaults", ["delete", "com.apple.dock", key])
            }
        }
        run("/usr/bin/killall", ["Dock"])
        UserDefaults.standard.removeObject(forKey: backupKey)
    }

    // MARK: - Private

    private static func backupIfNeeded() {
        guard !hasBackup else { return }

        let dock = UserDefaults(suiteName: "com.apple.dock")
        var backup: [String: Any] = [:]
        for key in keys {
            if let value = dock?.object(forKey: key) as? Bool {
                backup[key] = value
            } else {
                backup[key] = "unset"
            }
        }
        UserDefaults.standard.set(backup, forKey: backupKey)
    }

    private static func run(_ path: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        try? process.run()
        process.waitUntilExit()
    }
}

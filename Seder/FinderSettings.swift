import Foundation

/// Changes Finder settings by running the same commands you'd type in Terminal.
enum FinderSettings {

    /// Is "show icons on the Desktop" currently turned off?
    static var areDesktopIconsHidden: Bool {
        let finder = UserDefaults(suiteName: "com.apple.finder")
        return (finder?.object(forKey: "CreateDesktop") as? Bool) == false
    }

    /// Hides or shows all Desktop icons. Finder restarts for a moment.
    static func setDesktopIconsHidden(_ hidden: Bool) {
        run("/usr/bin/defaults", ["write", "com.apple.finder", "CreateDesktop", "-bool", hidden ? "false" : "true"])
        run("/usr/bin/killall", ["Finder"])
    }

    private static func run(_ path: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        try? process.run()
        process.waitUntilExit()
    }
}

import Foundation

enum Settings {

    private static let extContainerID = "com.quickmd.app.markdownpreview"
    private static let fileName = "com.quickmd.settings.plist"

    /// URL inside the extension's sandbox container.
    /// - From the extension (sandboxed): NSHomeDirectory() → container/Data/
    /// - From the host app (non-sandboxed): ~/Library/Containers/<id>/Data/
    static var fileURL: URL {
        let base: URL
        if Bundle.main.bundleIdentifier == extContainerID {
            // Running inside the extension — use sandbox home
            base = URL(fileURLWithPath: NSHomeDirectory())
        } else {
            // Running inside the host app (non-sandboxed)
            base = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers/\(extContainerID)/Data")
        }
        return base.appendingPathComponent("Library/Preferences/\(fileName)")
    }

    private static func read() -> [String: Any] {
        guard let dict = NSDictionary(contentsOf: fileURL) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    static func write(_ dict: [String: Any]) {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        (dict as NSDictionary).write(to: fileURL, atomically: true)
    }

    static var fontSize: Int {
        (read()["fontSize"] as? Int) ?? 100
    }

    static var theme: String {
        (read()["theme"] as? String) ?? "github"
    }

    static var colorScheme: String {
        (read()["colorScheme"] as? String) ?? "system"
    }

    static var defaultAction: String {
        (read()["defaultAction"] as? String) ?? "always"
    }

    private static let viewModeFileURL: URL = {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("com.quickmd.lastviewmode")
    }()

    static var lastViewMode: String {
        (try? String(contentsOf: viewModeFileURL, encoding: .utf8)) ?? "rendered"
    }

    static func setLastViewMode(_ mode: String) {
        try? mode.write(to: viewModeFileURL, atomically: true, encoding: .utf8)
    }

    static var startRendered: Bool {
        switch defaultAction {
        case "click": return false
        case "remember": return lastViewMode == "rendered"
        default: return true
        }
    }
}

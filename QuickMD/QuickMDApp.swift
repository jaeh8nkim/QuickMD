import SwiftUI

@main
struct QuickMDApp: App {
    var body: some Scene {
        Window("QuickMD", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

import SwiftUI

struct SettingsView: View {
    @State private var fontSize: Int = 100
    @State private var theme: String = "github"
    @State private var colorScheme: String = "system"
    @State private var defaultAction: String = "always"

    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section("Preview") {
                Picker("Font Size", selection: $fontSize) {
                    ForEach(Array(stride(from: 50, through: 150, by: 10)), id: \.self) { size in
                        Text("\(size)%").tag(size)
                    }
                }

                Picker("Theme", selection: $theme) {
                    Text("Basic").tag("basic")
                    Text("GitHub").tag("github")
                }

                Picker("Color Scheme", selection: $colorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

                Picker("Default Action", selection: $defaultAction) {
                    Text("Always Render").tag("always")
                    Text("Render on Click").tag("click")
                    Text("Remember Last").tag("remember")
                }
            }

            Section {
                HStack {
                    Image(systemName: "puzzlepiece.extension")
                        .foregroundStyle(.secondary)
                    Text("Enable the Quick Look extension in System Settings.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                            openURL(url)
                        }
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .onAppear { load() }
        .onChange(of: fontSize) { _ in save() }
        .onChange(of: theme) { _ in save() }
        .onChange(of: colorScheme) { _ in save() }
        .onChange(of: defaultAction) { _ in save() }
    }

    private func load() {
        fontSize = Settings.fontSize
        theme = Settings.theme
        colorScheme = Settings.colorScheme
        defaultAction = Settings.defaultAction
    }

    private func save() {
        Settings.write([
            "fontSize": fontSize,
            "theme": theme,
            "colorScheme": colorScheme,
            "defaultAction": defaultAction,
        ])
    }
}

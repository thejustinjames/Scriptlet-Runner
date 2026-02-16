import SwiftUI

@main
struct ScriptletRunnerApp: App {
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @State private var showingAbout = false
    @State private var showingHelp = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .preferredColorScheme(appearanceMode.colorScheme)
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
                .sheet(isPresented: $showingHelp) {
                    HelpView()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            // App Menu
            CommandGroup(replacing: .appInfo) {
                Button("About Scriptlet Runner") {
                    showingAbout = true
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .appSettings) {
                Divider()

                Menu("Appearance") {
                    Button("System") {
                        appearanceModeRaw = AppearanceMode.system.rawValue
                    }
                    Button("Light") {
                        appearanceModeRaw = AppearanceMode.light.rawValue
                    }
                    Button("Dark") {
                        appearanceModeRaw = AppearanceMode.dark.rawValue
                    }
                }
            }

            // Help Menu
            CommandGroup(replacing: .help) {
                Button("Scriptlet Runner Help") {
                    showingHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)

                Divider()

                Link("Visit GitHub", destination: URL(string: "https://github.com/thejustinjames")!)

                Divider()

                Button("Report an Issue...") {
                    if let url = URL(string: "https://github.com/thejustinjames/scriptletRunner/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }

        Settings {
            SettingsWindowView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}

struct SettingsWindowView: View {
    @AppStorage("scanLocations") private var scanLocationsData: Data = Data()
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var scanLocations: [ScanLocation] {
        (try? JSONDecoder().decode([ScanLocation].self, from: scanLocationsData)) ?? []
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        SettingsView(
            locations: Binding(
                get: { scanLocations },
                set: { newLocations in
                    if let data = try? JSONEncoder().encode(newLocations) {
                        scanLocationsData = data
                    }
                }
            ),
            appearanceMode: Binding(
                get: { appearanceMode },
                set: { appearanceModeRaw = $0.rawValue }
            )
        )
    }
}

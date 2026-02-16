import SwiftUI

enum SidebarSection: String, CaseIterable {
    case scripts = "Scripts"
    case chains = "Chains"
}

struct ContentView: View {
    @StateObject private var scanner = ScriptScanner()
    @StateObject private var scriptRunner = ScriptRunner()
    @StateObject private var chainRunner = ChainRunner()

    @AppStorage("scanLocations") private var scanLocationsData: Data = Data()
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("savedChains") private var savedChainsData: Data = Data()

    @State private var scripts: [Script] = []
    @State private var chains: [ScriptChain] = []
    @State private var selectedSection: SidebarSection = .scripts
    @State private var selectedScript: Script?
    @State private var selectedChain: ScriptChain?
    @State private var selectedArguments: [ScriptArgument] = []
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var showingChainEditor = false
    @State private var editingChain: ScriptChain?

    private var scanLocations: [ScanLocation] {
        (try? JSONDecoder().decode([ScanLocation].self, from: scanLocationsData)) ?? []
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Section picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(SidebarSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)

                Divider()

                // Content based on section
                switch selectedSection {
                case .scripts:
                    ScriptListView(
                        scripts: scripts,
                        selectedScript: $selectedScript,
                        searchText: $searchText
                    )
                case .chains:
                    VStack(spacing: 0) {
                        ChainListView(
                            chains: $chains,
                            selectedChain: $selectedChain
                        )

                        Divider()

                        // New chain button
                        Button {
                            createNewChain()
                        } label: {
                            Label("New Chain", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(8)
                    }
                }
            }
            .frame(minWidth: 280)
        } detail: {
            switch selectedSection {
            case .scripts:
                if let script = selectedScript {
                    VStack(spacing: 0) {
                        ScriptDetailView(
                            script: script,
                            arguments: $selectedArguments,
                            onRun: runSelectedScript
                        )

                        Divider()

                        ConsoleView(runner: scriptRunner)
                    }
                } else {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "Select a script",
                        subtitle: scripts.isEmpty ? "No scripts found. Add scan locations in Settings." : "Choose a script from the sidebar to view details."
                    )
                }

            case .chains:
                if let chain = selectedChain {
                    ChainDetailView(
                        chain: chain,
                        scripts: scripts,
                        runner: chainRunner,
                        onEdit: {
                            editingChain = chain
                            showingChainEditor = true
                        },
                        onDelete: {
                            deleteChain(chain)
                        }
                    )
                } else {
                    EmptyStateView(
                        icon: "link",
                        title: "Select a chain",
                        subtitle: chains.isEmpty ? "Create a chain to run multiple scripts in sequence." : "Choose a chain from the sidebar to view details."
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    refreshScripts()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh Scripts")
                .keyboardShortcut("r", modifiers: .command)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
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
        .sheet(isPresented: $showingChainEditor) {
            if let chain = editingChain {
                ChainEditorView(
                    chain: Binding(
                        get: { chain },
                        set: { editingChain = $0 }
                    ),
                    scripts: scripts,
                    isNew: !chains.contains(where: { $0.id == chain.id }),
                    onSave: saveChain
                )
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear {
            refreshScripts()
            loadChains()
        }
        .onChange(of: selectedScript) { newScript in
            if let script = newScript {
                selectedArguments = script.arguments
            } else {
                selectedArguments = []
            }
        }
        .onChange(of: selectedSection) { _ in
            // Clear selection when switching sections
            selectedScript = nil
            selectedChain = nil
        }
        .onChange(of: scanLocationsData) { _ in
            refreshScripts()
        }
    }

    // MARK: - Scripts

    private func refreshScripts() {
        scripts = scanner.scan(locations: scanLocations)
    }

    private func runSelectedScript() {
        guard let script = selectedScript else { return }
        scriptRunner.run(script: script, arguments: selectedArguments)
    }

    // MARK: - Chains

    private func loadChains() {
        chains = (try? JSONDecoder().decode([ScriptChain].self, from: savedChainsData)) ?? []
    }

    private func saveChains() {
        if let data = try? JSONEncoder().encode(chains) {
            savedChainsData = data
        }
    }

    private func createNewChain() {
        let newChain = ScriptChain(name: "New Chain")
        editingChain = newChain
        showingChainEditor = true
    }

    private func saveChain(_ chain: ScriptChain) {
        if let index = chains.firstIndex(where: { $0.id == chain.id }) {
            chains[index] = chain
        } else {
            chains.append(chain)
        }
        saveChains()
        selectedChain = chain
    }

    private func deleteChain(_ chain: ScriptChain) {
        chains.removeAll { $0.id == chain.id }
        saveChains()
        selectedChain = nil
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

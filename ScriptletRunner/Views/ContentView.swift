import SwiftUI
import UniformTypeIdentifiers

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
    @AppStorage("scriptIcons") private var scriptIconsData: Data = Data()
    @AppStorage("clearConsoleOnRun") private var clearConsoleOnRun: Bool = true
    @AppStorage("favoriteScripts") private var favoriteScriptsData: Data = Data()

    private var favoriteScripts: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteScriptsData)) ?? []
    }

    private func toggleFavorite(path: String) {
        var favorites = favoriteScripts
        if favorites.contains(path) {
            favorites.remove(path)
        } else {
            favorites.insert(path)
        }
        if let data = try? JSONEncoder().encode(favorites) {
            favoriteScriptsData = data
        }
    }

    @State private var scripts: [Script] = []
    @State private var chains: [ScriptChain] = []
    @State private var selectedSection: SidebarSection = .scripts
    @State private var selectedScript: Script?
    @State private var selectedChain: ScriptChain?
    @State private var selectedArguments: [ScriptArgument] = []
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var editingChain: ScriptChain?
    @State private var showingHistory = false

    private var scanLocations: [ScanLocation] {
        (try? JSONDecoder().decode([ScanLocation].self, from: scanLocationsData)) ?? []
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var scriptIcons: [String: String] {
        get { (try? JSONDecoder().decode([String: String].self, from: scriptIconsData)) ?? [:] }
    }

    private func setScriptIcon(_ icon: String?, for path: String) {
        var icons = scriptIcons
        icons[path] = icon
        if let data = try? JSONEncoder().encode(icons) {
            scriptIconsData = data
        }
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
                        searchText: $searchText,
                        scriptIcons: Binding(
                            get: { scriptIcons },
                            set: { newIcons in
                                if let data = try? JSONEncoder().encode(newIcons) {
                                    scriptIconsData = data
                                }
                            }
                        ),
                        favoriteScripts: favoriteScripts,
                        onDoubleClick: { script in
                            selectedScript = script
                            selectedArguments = script.arguments
                            runSelectedScript()
                        },
                        onToggleFavorite: { path in
                            toggleFavorite(path: path)
                        }
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
                            icon: scriptIcons[script.path],
                            onRun: runSelectedScript,
                            onIconChange: { newIcon in
                                setScriptIcon(newIcon, for: script.path)
                            }
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
                    showingHistory.toggle()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help("Run History")
                .popover(isPresented: $showingHistory) {
                    HistoryPopover(isPresented: $showingHistory) { scriptPath in
                        // Find and select the script from history
                        if let script = scripts.first(where: { $0.path == scriptPath }) {
                            selectedSection = .scripts
                            selectedScript = script
                            selectedArguments = script.arguments
                        }
                    }
                }
            }

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
                ),
                clearConsoleOnRun: $clearConsoleOnRun
            )
        }
        .sheet(item: $editingChain) { chain in
            ChainEditorView(
                chain: Binding(
                    get: { chain },
                    set: { editingChain = $0 }
                ),
                scripts: scripts,
                isNew: !chains.contains(where: { $0.id == chain.id }),
                onSave: { savedChain in
                    saveChain(savedChain)
                    editingChain = nil
                }
            )
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleFileDrop(providers: providers)
            return true
        }
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
        .onChange(of: scriptRunner.exitCode) { newExitCode in
            if let exitCode = newExitCode {
                RunHistoryManager.shared.updateLastEntryExitCode(exitCode)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("QuickRunScript"))) { notification in
            if selectedSection == .scripts,
               let userInfo = notification.userInfo,
               let index = userInfo["index"] as? Int {
                // Get scripts sorted by favorites first, then alphabetically (same as ScriptListView)
                let sortedScripts = scripts.sorted { script1, script2 in
                    let isFav1 = favoriteScripts.contains(script1.path)
                    let isFav2 = favoriteScripts.contains(script2.path)
                    if isFav1 != isFav2 {
                        return isFav1
                    }
                    return script1.name.localizedCaseInsensitiveCompare(script2.name) == .orderedAscending
                }
                if index < sortedScripts.count {
                    selectedScript = sortedScripts[index]
                    selectedArguments = sortedScripts[index].arguments
                    runSelectedScript()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshScripts"))) { _ in
            refreshScripts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RunSelectedScript"))) { _ in
            if selectedSection == .scripts && selectedScript != nil {
                runSelectedScript()
            }
        }
    }

    // MARK: - Scripts

    private func refreshScripts() {
        scripts = scanner.scan(locations: scanLocations)
    }

    private func runSelectedScript() {
        guard let script = selectedScript else { return }
        if clearConsoleOnRun {
            scriptRunner.clear()
        }

        // Record to history
        RunHistoryManager.shared.addEntry(
            scriptPath: script.path,
            scriptName: script.displayName,
            arguments: selectedArguments
        )

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
        editingChain = ScriptChain(name: "New Chain")
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

    // MARK: - Drag & Drop

    private func handleFileDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                // Check if it's a shell script
                if url.pathExtension == "sh" || self.isShellScript(url) {
                    let folderPath = url.deletingLastPathComponent().path
                    DispatchQueue.main.async {
                        self.addScanLocation(path: folderPath)
                    }
                }
            }
        }
    }

    private func isShellScript(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let header = String(data: data.prefix(64), encoding: .utf8) else {
            return false
        }
        return header.hasPrefix("#!/bin/bash") ||
               header.hasPrefix("#!/bin/sh") ||
               header.hasPrefix("#!/usr/bin/env bash") ||
               header.hasPrefix("#!/usr/bin/env sh")
    }

    private func addScanLocation(path: String) {
        var locations = scanLocations
        // Only add if not already present
        if !locations.contains(where: { $0.path == path }) {
            locations.append(ScanLocation(path: path))
            if let data = try? JSONEncoder().encode(locations) {
                scanLocationsData = data
            }
        }
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

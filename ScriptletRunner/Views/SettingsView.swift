import SwiftUI
import AppKit

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var locations: [ScanLocation]
    @Binding var appearanceMode: AppearanceMode
    @Binding var clearConsoleOnRun: Bool
    @State private var selectedLocation: ScanLocation?

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            TabView {
            // Scan Locations Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("Scan Locations")
                    .font(.headline)

                Text("Add folders containing shell scripts to scan.")
                    .foregroundColor(.secondary)

                List(selection: $selectedLocation) {
                    ForEach(locations) { location in
                        LocationRow(location: binding(for: location))
                            .tag(location)
                    }
                    .onDelete(perform: deleteLocations)
                }
                .frame(minHeight: 200)

                HStack {
                    Button {
                        showFolderPicker()
                    } label: {
                        Label("Add Folder", systemImage: "plus")
                    }

                    Button {
                        if let selected = selectedLocation,
                           let index = locations.firstIndex(where: { $0.id == selected.id }) {
                            locations.remove(at: index)
                            selectedLocation = nil
                        }
                    } label: {
                        Label("Remove", systemImage: "minus")
                    }
                    .disabled(selectedLocation == nil)

                    Spacer()
                }
            }
            .padding()
            .tabItem {
                Label("Locations", systemImage: "folder")
            }

            // Appearance Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("Appearance")
                    .font(.headline)

                Picker("Theme", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)

                Text("Choose between light, dark, or system appearance.")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }

            // Behavior Tab
            VStack(alignment: .leading, spacing: 16) {
                Text("Behavior")
                    .font(.headline)

                Toggle("Clear console before each run", isOn: $clearConsoleOnRun)

                Text("Automatically clear the console output when running a new script.")
                    .foregroundColor(.secondary)
                    .font(.caption)

                Spacer()
            }
            .padding()
            .tabItem {
                Label("Behavior", systemImage: "gearshape.2")
            }
            }
        }
        .frame(width: 500, height: 450)
    }

    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing shell scripts"
        panel.prompt = "Add Folder"
        panel.showsHiddenFiles = false
        panel.treatsFilePackagesAsDirectories = false

        // Present as sheet on the key window if available, otherwise use modal
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    let newLocation = ScanLocation(path: url.path)
                    if !self.locations.contains(where: { $0.path == newLocation.path }) {
                        self.locations.append(newLocation)
                    }
                }
            }
        } else {
            if panel.runModal() == .OK, let url = panel.url {
                let newLocation = ScanLocation(path: url.path)
                if !locations.contains(where: { $0.path == newLocation.path }) {
                    locations.append(newLocation)
                }
            }
        }
    }

    private func binding(for location: ScanLocation) -> Binding<ScanLocation> {
        guard let index = locations.firstIndex(where: { $0.id == location.id }) else {
            return .constant(location)
        }
        return $locations[index]
    }

    private func deleteLocations(at offsets: IndexSet) {
        locations.remove(atOffsets: offsets)
    }
}

struct LocationRow: View {
    @Binding var location: ScanLocation

    var body: some View {
        HStack {
            Toggle("", isOn: $location.isEnabled)
                .labelsHidden()

            VStack(alignment: .leading) {
                Text(location.label)
                    .fontWeight(.medium)

                Text(location.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Toggle("Recursive", isOn: $location.recursive)
                .toggleStyle(.switch)
                .controlSize(.small)

            if !location.exists {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .help("Folder not found")
            }
        }
        .padding(.vertical, 4)
    }
}

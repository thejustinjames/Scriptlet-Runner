import SwiftUI

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
    @State private var selectedLocation: ScanLocation?
    @State private var showingFilePicker = false

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
                        showingFilePicker = true
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
            }
        }
        .frame(width: 500, height: 450)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let newLocation = ScanLocation(path: url.path)
                    if !locations.contains(where: { $0.path == newLocation.path }) {
                        locations.append(newLocation)
                    }
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
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

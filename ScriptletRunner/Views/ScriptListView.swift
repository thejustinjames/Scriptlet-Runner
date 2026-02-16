import SwiftUI

struct ScriptListView: View {
    let scripts: [Script]
    @Binding var selectedScript: Script?
    @Binding var searchText: String
    @Binding var scriptIcons: [String: String]  // path -> SF Symbol name

    var filteredScripts: [Script] {
        if searchText.isEmpty {
            return scripts
        }
        return scripts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search scripts...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Script list
            List(selection: $selectedScript) {
                ForEach(filteredScripts) { script in
                    ScriptRow(script: script, icon: scriptIcons[script.path])
                        .tag(script)
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct ScriptRow: View {
    let script: Script
    let icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon ?? "doc.text")
                    .foregroundColor(.accentColor)
                    .frame(width: 20)

                Text(script.displayName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                if !script.isExecutable {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .help("Script is not executable")
                }
            }

            if !script.description.isEmpty {
                Text(script.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Text(script.directory)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.vertical, 4)
    }
}

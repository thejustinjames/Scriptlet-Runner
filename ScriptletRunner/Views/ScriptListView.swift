import SwiftUI

struct ScriptListView: View {
    let scripts: [Script]
    @Binding var selectedScript: Script?
    @Binding var searchText: String
    @Binding var scriptIcons: [String: String]  // path -> SF Symbol name
    let favoriteScripts: Set<String>
    var onDoubleClick: ((Script) -> Void)?
    var onToggleFavorite: ((String) -> Void)?

    var filteredScripts: [Script] {
        let filtered: [Script]
        if searchText.isEmpty {
            filtered = scripts
        } else {
            filtered = scripts.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Sort favorites to top
        return filtered.sorted { script1, script2 in
            let isFav1 = favoriteScripts.contains(script1.path)
            let isFav2 = favoriteScripts.contains(script2.path)
            if isFav1 != isFav2 {
                return isFav1
            }
            return script1.name.localizedCaseInsensitiveCompare(script2.name) == .orderedAscending
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
                    ScriptRow(
                        script: script,
                        icon: scriptIcons[script.path],
                        isFavorite: favoriteScripts.contains(script.path),
                        onToggleFavorite: { onToggleFavorite?(script.path) }
                    )
                    .tag(script)
                    .onTapGesture(count: 2) {
                        selectedScript = script
                        onDoubleClick?(script)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct ScriptRow: View {
    let script: Script
    let icon: String?
    let isFavorite: Bool
    var onToggleFavorite: (() -> Void)?

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

                if isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }

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
        .contextMenu {
            Button {
                onToggleFavorite?()
            } label: {
                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: isFavorite ? "star.slash" : "star")
            }
        }
    }
}

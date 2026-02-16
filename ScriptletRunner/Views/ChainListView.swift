import SwiftUI

struct ChainListView: View {
    @Binding var chains: [ScriptChain]
    @Binding var selectedChain: ScriptChain?
    @State private var searchText = ""

    var filteredChains: [ScriptChain] {
        if searchText.isEmpty {
            return chains
        }
        return chains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.accentColor)
                Text("Script Chains")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search chains...", text: $searchText)
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

            // Chain list
            if filteredChains.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No chains yet")
                        .foregroundColor(.secondary)
                    Text("Create a chain to run multiple scripts in sequence")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(selection: $selectedChain) {
                    ForEach(filteredChains) { chain in
                        ChainRow(chain: chain)
                            .tag(chain)
                    }
                    .onDelete(perform: deleteChains)
                }
                .listStyle(.sidebar)
            }
        }
    }

    private func deleteChains(at offsets: IndexSet) {
        let chainsToDelete = offsets.map { filteredChains[$0] }
        chains.removeAll { chain in
            chainsToDelete.contains { $0.id == chain.id }
        }
        if let selected = selectedChain, chainsToDelete.contains(where: { $0.id == selected.id }) {
            selectedChain = nil
        }
    }
}

struct ChainRow: View {
    let chain: ScriptChain

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.accentColor)
                Text(chain.name)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Text("\(chain.stepCount) steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(4)
            }

            if !chain.description.isEmpty {
                Text(chain.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let lastRun = chain.lastRunAt {
                Text("Last run: \(lastRun.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

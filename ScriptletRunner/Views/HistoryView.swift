import SwiftUI

struct HistoryView: View {
    @State private var history: [RunHistoryEntry] = []
    var onSelectScript: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Run History")
                    .font(.headline)

                Spacer()

                Button {
                    RunHistoryManager.shared.clearHistory()
                    history = []
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(history.isEmpty)
                .help("Clear History")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .foregroundColor(.secondary)
                    Text("Run scripts to see them here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(history) { entry in
                        HistoryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectScript?(entry.scriptPath)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            history = RunHistoryManager.shared.getHistory()
        }
    }
}

struct HistoryRow: View {
    let entry: RunHistoryEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.scriptName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !entry.arguments.isEmpty {
                        Text("with \(entry.arguments.count) args")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        guard let code = entry.exitCode else { return .secondary }
        return code == 0 ? .green : .red
    }
}

struct HistoryPopover: View {
    @Binding var isPresented: Bool
    var onSelectScript: ((String) -> Void)?

    var body: some View {
        HistoryView(onSelectScript: { path in
            onSelectScript?(path)
            isPresented = false
        })
        .frame(width: 300, height: 400)
    }
}

import SwiftUI

struct ChainDetailView: View {
    let chain: ScriptChain
    let scripts: [Script]
    @ObservedObject var runner: ChainRunner
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "link")
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading) {
                        Text(chain.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if !chain.description.isEmpty {
                            Text(chain.description)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .help("Edit Chain")

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Delete Chain")
                }

                HStack {
                    Label("\(chain.stepCount) steps", systemImage: "list.number")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastRun = chain.lastRunAt {
                        Divider()
                            .frame(height: 12)
                        Label("Last run: \(lastRun.formatted())", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Steps list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)

                    ForEach(Array(chain.steps.enumerated()), id: \.element.id) { index, step in
                        ChainStepRow(
                            step: step,
                            index: index,
                            script: scripts.first { $0.path == step.scriptPath },
                            status: runner.stepStatuses[step.id],
                            isRunning: runner.isRunning && runner.currentStepIndex == index
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: 250)

            Divider()

            // Run controls
            HStack {
                if runner.isRunning {
                    Button {
                        runner.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    ProgressView()
                        .scaleEffect(0.7)

                    Text("Running step \(runner.currentStepIndex + 1) of \(chain.stepCount)...")
                        .foregroundColor(.secondary)
                } else {
                    Button {
                        runner.run(chain: chain, scripts: scripts)
                    } label: {
                        Label("Run Chain", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(chain.steps.isEmpty)
                }

                Spacer()

                if !runner.output.isEmpty {
                    Button {
                        runner.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(runner.output, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .disabled(runner.output.isEmpty)
            }
            .padding()

            Divider()

            // Output console
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Output")
                        .font(.headline)

                    Spacer()

                    if !runner.isRunning && !runner.output.isEmpty {
                        if runner.overallSuccess {
                            Label("Success", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("Failed", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollView {
                    Text(runner.output.isEmpty ? "Run the chain to see output..." : runner.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(runner.output.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
            .frame(minHeight: 150)
        }
    }
}

struct ChainStepRow: View {
    let step: ScriptChainStep
    let index: Int
    let script: Script?
    let status: ChainStepStatus?
    let isRunning: Bool

    var body: some View {
        HStack {
            // Step number with status
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 28, height: 28)

                if isRunning {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading) {
                Text(step.scriptName)
                    .fontWeight(.medium)

                if script == nil {
                    Text("Script not found")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if step.continueOnError {
                    Text("Continue on error")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Status indicator
            if let status = status {
                statusLabel(for: status)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        guard let status = status else {
            return .gray
        }

        switch status {
        case .pending:
            return .gray
        case .running:
            return .blue
        case .completed(let code):
            return code == 0 ? .green : .orange
        case .failed:
            return .red
        case .skipped:
            return .gray
        }
    }

    @ViewBuilder
    private func statusLabel(for status: ChainStepStatus) -> some View {
        switch status {
        case .pending:
            Text("Pending")
                .font(.caption)
                .foregroundColor(.secondary)
        case .running:
            Text("Running...")
                .font(.caption)
                .foregroundColor(.blue)
        case .completed(let code):
            Label("Exit: \(code)", systemImage: code == 0 ? "checkmark.circle" : "exclamationmark.circle")
                .font(.caption)
                .foregroundColor(code == 0 ? .green : .orange)
        case .failed(let error):
            Label(error, systemImage: "xmark.circle")
                .font(.caption)
                .foregroundColor(.red)
        case .skipped:
            Text("Skipped")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

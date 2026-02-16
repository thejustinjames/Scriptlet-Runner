import SwiftUI

struct ScriptDetailView: View {
    let script: Script
    @Binding var arguments: [ScriptArgument]
    let onRun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(script.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if !script.description.isEmpty {
                    Text(script.description)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text(script.directory)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if let usage = script.usage {
                    HStack(alignment: .top) {
                        Text("Usage:")
                            .fontWeight(.medium)
                        Text(usage)
                            .font(.system(.body, design: .monospaced))
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Arguments section
            if !arguments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Arguments & Options")
                        .font(.headline)

                    ForEach($arguments) { $arg in
                        ArgumentRow(argument: $arg)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            // Run button
            HStack {
                Spacer()
                Button(action: onRun) {
                    Label("Run Script", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }
}

struct ArgumentRow: View {
    @Binding var argument: ScriptArgument

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $argument.isEnabled)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                Text(argument.displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(argument.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if argument.requiresValue && argument.isEnabled {
                    TextField(argument.placeholder ?? "Value", text: $argument.value)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

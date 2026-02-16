import SwiftUI

// Common SF Symbols for scripts
let availableIcons = [
    "doc.text", "terminal", "gearshape", "hammer", "wrench",
    "server.rack", "externaldrive", "network", "wifi", "antenna.radiowaves.left.and.right",
    "cloud", "arrow.triangle.2.circlepath", "arrow.clockwise", "play", "stop",
    "folder", "archivebox", "tray", "cylinder", "cpu",
    "memorychip", "bolt", "flame", "drop", "leaf",
    "star", "flag", "bell", "tag", "bookmark",
    "checkmark.circle", "xmark.circle", "exclamationmark.triangle", "info.circle", "questionmark.circle"
]

struct ScriptDetailView: View {
    let script: Script
    @Binding var arguments: [ScriptArgument]
    let icon: String?
    let onRun: () -> Void
    let onIconChange: (String?) -> Void

    @State private var showingIconPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    // Icon button
                    Button {
                        showingIconPicker = true
                    } label: {
                        Image(systemName: icon ?? "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                            .frame(width: 50, height: 50)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Click to change icon")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(script.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if !script.description.isEmpty {
                            Text(script.description)
                                .foregroundColor(.secondary)
                        }
                    }
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
        .popover(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: icon, onSelect: { newIcon in
                onIconChange(newIcon)
                showingIconPicker = false
            })
        }
    }
}

struct IconPickerView: View {
    let selectedIcon: String?
    let onSelect: (String?) -> Void

    let columns = [GridItem(.adaptive(minimum: 44))]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Icon")
                .font(.headline)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    // Default icon option
                    Button {
                        onSelect(nil)
                    } label: {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(selectedIcon == nil ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Default")

                    ForEach(availableIcons, id: \.self) { iconName in
                        Button {
                            onSelect(iconName)
                        } label: {
                            Image(systemName: iconName)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == iconName ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help(iconName)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .frame(width: 280)
    }
}

struct ArgumentRow: View {
    @Binding var argument: ScriptArgument

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Show toggle for non-choice arguments
            if argument.choices == nil {
                Toggle("", isOn: $argument.isEnabled)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                // For choice arguments, show as picker
                if let choices = argument.choices {
                    Text("Mode")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)

                    Picker("", selection: $argument.value) {
                        Text("Select...").tag("")
                        ForEach(choices, id: \.self) { choice in
                            Text(choice).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    .onChange(of: argument.value) { newValue in
                        argument.isEnabled = !newValue.isEmpty
                    }
                } else {
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
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

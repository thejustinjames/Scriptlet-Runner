import SwiftUI

struct ChainEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var chain: ScriptChain
    let scripts: [Script]
    let isNew: Bool
    let onSave: (ScriptChain) -> Void

    @State private var editedChain: ScriptChain
    @State private var selectedStepIndex: Int?
    @State private var showingScriptPicker = false

    init(chain: Binding<ScriptChain>, scripts: [Script], isNew: Bool, onSave: @escaping (ScriptChain) -> Void) {
        self._chain = chain
        self.scripts = scripts
        self.isNew = isNew
        self.onSave = onSave
        self._editedChain = State(initialValue: chain.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isNew ? "New Chain" : "Edit Chain")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveChain()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(editedChain.name.isEmpty || editedChain.steps.isEmpty)
            }
            .padding()

            Divider()

            Form {
                Section("Chain Details") {
                    TextField("Name", text: $editedChain.name)
                    TextField("Description (optional)", text: $editedChain.description)
                }

                Section("Steps") {
                    if editedChain.steps.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("Add scripts to create a chain")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(Array(editedChain.steps.enumerated()), id: \.element.id) { index, step in
                            StepRow(
                                step: binding(for: step),
                                index: index,
                                script: scripts.first { $0.path == step.scriptPath },
                                onRemove: { removeStep(at: index) }
                            )
                        }
                        .onMove(perform: moveSteps)
                    }

                    Button {
                        showingScriptPicker = true
                    } label: {
                        Label("Add Script", systemImage: "plus")
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingScriptPicker) {
            ScriptPickerView(scripts: scripts) { script in
                addStep(for: script)
            }
        }
    }

    private func binding(for step: ScriptChainStep) -> Binding<ScriptChainStep> {
        guard let index = editedChain.steps.firstIndex(where: { $0.id == step.id }) else {
            return .constant(step)
        }
        return $editedChain.steps[index]
    }

    private func addStep(for script: Script) {
        let step = ScriptChainStep(
            scriptPath: script.path,
            scriptName: script.name
        )
        editedChain.steps.append(step)
    }

    private func removeStep(at index: Int) {
        editedChain.steps.remove(at: index)
    }

    private func moveSteps(from source: IndexSet, to destination: Int) {
        editedChain.steps.move(fromOffsets: source, toOffset: destination)
    }

    private func saveChain() {
        chain = editedChain
        onSave(editedChain)
        dismiss()
    }
}

struct StepRow: View {
    @Binding var step: ScriptChainStep
    let index: Int
    let script: Script?
    let onRemove: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "\(index + 1).circle.fill")
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading) {
                    Text(step.scriptName)
                        .fontWeight(.medium)

                    if script == nil {
                        Text("Script not found")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                Toggle("Continue on error", isOn: $step.continueOnError)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            if isExpanded, let script = script {
                StepArgumentsEditor(step: $step, script: script)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StepArgumentsEditor: View {
    @Binding var step: ScriptChainStep
    let script: Script

    var body: some View {
        if script.arguments.isEmpty {
            Text("No arguments available")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Arguments")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(script.arguments) { arg in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { step.enabledFlags.contains(arg.id.uuidString) },
                            set: { enabled in
                                if enabled {
                                    step.enabledFlags.append(arg.id.uuidString)
                                } else {
                                    step.enabledFlags.removeAll { $0 == arg.id.uuidString }
                                }
                            }
                        ))
                        .labelsHidden()

                        Text(arg.displayName)
                            .font(.system(.caption, design: .monospaced))

                        if arg.requiresValue && step.enabledFlags.contains(arg.id.uuidString) {
                            TextField(arg.placeholder ?? "Value", text: Binding(
                                get: { step.arguments[arg.id.uuidString] ?? "" },
                                set: { step.arguments[arg.id.uuidString] = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                        }

                        Spacer()
                    }
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
    }
}

struct ScriptPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let scripts: [Script]
    let onSelect: (Script) -> Void

    @State private var searchText = ""

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
            HStack {
                Text("Select Script")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search scripts...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)

            Divider()

            List {
                ForEach(filteredScripts) { script in
                    Button {
                        onSelect(script)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(script.name)
                                .fontWeight(.medium)
                            if !script.description.isEmpty {
                                Text(script.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 400, height: 400)
    }
}

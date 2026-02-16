import SwiftUI

struct ConsoleView: View {
    @ObservedObject var runner: ScriptRunner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Console Output")
                    .font(.headline)

                Spacer()

                if runner.isRunning {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)

                    Button("Stop") {
                        runner.stop()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                if let code = runner.exitCode {
                    Text("Exit: \(code)")
                        .font(.caption)
                        .foregroundColor(code == 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(code == 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)
                }

                Button {
                    runner.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(runner.output.isEmpty)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(runner.output, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .disabled(runner.output.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(runner.output.isEmpty ? "No output yet..." : runner.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(runner.output.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                        .id("output")
                }
                .onChange(of: runner.output) { _ in
                    withAnimation {
                        proxy.scrollTo("output", anchor: .bottom)
                    }
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
        .frame(minHeight: 150)
    }
}

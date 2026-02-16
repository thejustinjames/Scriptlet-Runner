import SwiftUI
import AppKit

struct ConsoleView: View {
    @ObservedObject var runner: ScriptRunner
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    // Strip ANSI for URL detection and search
    private var plainOutput: String {
        ANSIParser.stripANSI(runner.output)
    }

    // Extract URLs from output
    var detectedURLs: [URL] {
        let pattern = #"https?://[^\s\"\'\<\>\]\)]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: plainOutput, range: NSRange(plainOutput.startIndex..., in: plainOutput))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: plainOutput) else { return nil }
            return URL(string: String(plainOutput[range]))
        }
    }

    // Search match count
    private var searchMatchCount: Int {
        guard !searchText.isEmpty else { return 0 }
        let pattern = NSRegularExpression.escapedPattern(for: searchText)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return 0 }
        return regex.numberOfMatches(in: plainOutput, range: NSRange(plainOutput.startIndex..., in: plainOutput))
    }

    // Parsed output with ANSI colors and search highlighting
    private var attributedOutput: AttributedString {
        if runner.output.isEmpty {
            var placeholder = AttributedString("No output yet...")
            placeholder.foregroundColor = .secondary
            return placeholder
        }

        var result = ANSIParser.parse(runner.output)

        // Highlight search matches
        if !searchText.isEmpty {
            let plainText = ANSIParser.stripANSI(runner.output)
            let pattern = NSRegularExpression.escapedPattern(for: searchText)
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: plainText, range: NSRange(plainText.startIndex..., in: plainText))

                // Convert NSRange matches to AttributedString ranges
                for match in matches.reversed() {
                    if let swiftRange = Range(match.range, in: plainText) {
                        // Find corresponding range in attributed string
                        let startOffset = plainText.distance(from: plainText.startIndex, to: swiftRange.lowerBound)
                        let endOffset = plainText.distance(from: plainText.startIndex, to: swiftRange.upperBound)

                        // Bounds check before accessing
                        let charCount = result.characters.count
                        if startOffset < charCount && endOffset <= charCount {
                            let attrStart = result.index(result.startIndex, offsetByCharacters: startOffset)
                            let attrEnd = result.index(result.startIndex, offsetByCharacters: endOffset)
                            result[attrStart..<attrEnd].backgroundColor = Color.yellow
                            result[attrStart..<attrEnd].foregroundColor = Color.black
                        }
                    }
                }
            }
        }

        return result
    }

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

                // URL buttons if URLs detected
                if let url = detectedURLs.first {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url.absoluteString, forType: .string)
                    } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(.bordered)
                    .help("Copy URL")

                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .help("Open URL in Browser")
                }

                // Search toggle
                Button {
                    isSearching.toggle()
                    if isSearching {
                        isSearchFocused = true
                    } else {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: isSearching ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help("Search (⌘F)")

                Button {
                    runner.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(runner.output.isEmpty)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(plainOutput, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .disabled(runner.output.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            // Search bar
            if isSearching {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search output...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Text("\(searchMatchCount) matches")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }

                    Button {
                        isSearching = false
                        searchText = ""
                    } label: {
                        Text("Done")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            }

            Divider()

            // Output area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(attributedOutput)
                        .font(.system(.body, design: .monospaced))
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleConsoleSearch"))) { _ in
            isSearching.toggle()
            if isSearching {
                isSearchFocused = true
            } else {
                searchText = ""
            }
        }
    }
}

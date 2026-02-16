import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Help")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Getting Started
                    HelpSection(title: "Getting Started", icon: "play.circle") {
                        Text("1. Open Settings (gear icon) and add folders containing your shell scripts")
                        Text("2. Scripts will be scanned and displayed in the sidebar")
                        Text("3. Click a script to see its details and available options")
                        Text("4. Configure any arguments and click Run to execute")
                    }

                    // Script Format
                    HelpSection(title: "Script Comment Format", icon: "doc.text") {
                        Text("Scriptlet Runner parses your script headers to extract metadata. Use this format:")
                            .padding(.bottom, 8)

                        CodeBlock("""
                        #!/bin/bash
                        # Description: What this script does
                        #
                        # Usage: script.sh [OPTIONS] <args>
                        #
                        # Options:
                        #   -h, --help      Show help
                        #   -v, --verbose   Verbose output
                        #   -f, --file FILE Input file
                        #
                        # Arguments:
                        #   input           Input file path
                        """)
                    }

                    // Running Scripts
                    HelpSection(title: "Running Scripts", icon: "terminal") {
                        Text("• Enable/disable options using the checkboxes")
                        Text("• Enter values for options that require input")
                        Text("• Click 'Run Script' to execute")
                        Text("• Output appears in the console below")
                        Text("• Use Stop to terminate a running script")
                        Text("• Copy output using the copy button")
                    }

                    // Settings
                    HelpSection(title: "Settings", icon: "gearshape") {
                        Text("**Scan Locations**: Folders to search for .sh scripts")
                        Text("**Recursive**: Include subdirectories in scan")
                        Text("**Appearance**: Light, Dark, or System theme")
                    }

                    // Keyboard Shortcuts
                    HelpSection(title: "Keyboard Shortcuts", icon: "keyboard") {
                        HStack {
                            Text("Settings")
                            Spacer()
                            Text("⌘,")
                                .font(.system(.body, design: .monospaced))
                        }
                        HStack {
                            Text("Refresh Scripts")
                            Spacer()
                            Text("⌘R")
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    // Support
                    HelpSection(title: "Support & Feedback", icon: "questionmark.circle") {
                        Text("Visit the GitHub repository for issues and feature requests:")

                        Link("github.com/thejustinjames", destination: URL(string: "https://github.com/thejustinjames")!)
                    }
                }
                .padding()
            }
        }
        .frame(width: 550, height: 600)
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .font(.callout)
            .foregroundColor(.secondary)
        }
    }
}

struct CodeBlock: View {
    let code: String

    init(_ code: String) {
        self.code = code
    }

    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
    }
}

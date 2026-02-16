import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    let appVersion = "1.0.0"
    let buildNumber = "1"

    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            // App Name
            Text("Scriptlet Runner")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Run all your scripts from a single place")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()

            // Version
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 40)

            // Author
            VStack(spacing: 8) {
                Text("Created by")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Justin James")
                    .font(.headline)

                Link("github.com/thejustinjames", destination: URL(string: "https://github.com/thejustinjames")!)
                    .font(.caption)
            }

            Divider()
                .padding(.horizontal, 40)

            // License
            VStack(spacing: 8) {
                Text("License")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Free for Non-Commercial Use")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Commercial use requires a license.\nFeel free to donate if you find this useful!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Donate Button
            Link(destination: URL(string: "https://github.com/thejustinjames")!) {
                Label("Support on GitHub", systemImage: "heart.fill")
                    .foregroundColor(.pink)
            }
            .buttonStyle(.bordered)

            // Close Button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .padding(.bottom)
        }
        .frame(width: 350, height: 480)
        .padding()
    }
}

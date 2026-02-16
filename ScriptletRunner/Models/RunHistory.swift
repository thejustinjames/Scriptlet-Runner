import Foundation

struct RunHistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let scriptPath: String
    let scriptName: String
    let runDate: Date
    let exitCode: Int32?
    let arguments: [String]

    init(scriptPath: String, scriptName: String, exitCode: Int32? = nil, arguments: [String] = []) {
        self.id = UUID()
        self.scriptPath = scriptPath
        self.scriptName = scriptName
        self.runDate = Date()
        self.exitCode = exitCode
        self.arguments = arguments
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: runDate, relativeTo: Date())
    }

    var statusIcon: String {
        guard let code = exitCode else { return "questionmark.circle" }
        return code == 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
}

class RunHistoryManager {
    static let shared = RunHistoryManager()
    private let maxHistoryEntries = 50

    private init() {}

    func addEntry(scriptPath: String, scriptName: String, arguments: [ScriptArgument]) {
        var history = getHistory()

        // Create argument strings for enabled arguments
        let argStrings = arguments.compactMap { arg -> String? in
            guard arg.isEnabled else { return nil }
            if let flag = arg.flagForCommand {
                if arg.requiresValue && !arg.value.isEmpty {
                    return "\(flag) \(arg.value)"
                } else if !arg.requiresValue {
                    return flag
                }
            }
            return nil
        }

        let entry = RunHistoryEntry(
            scriptPath: scriptPath,
            scriptName: scriptName,
            arguments: argStrings
        )

        history.insert(entry, at: 0)

        // Keep only the most recent entries
        if history.count > maxHistoryEntries {
            history = Array(history.prefix(maxHistoryEntries))
        }

        saveHistory(history)
    }

    func updateLastEntryExitCode(_ exitCode: Int32) {
        var history = getHistory()
        guard !history.isEmpty else { return }

        // Update the most recent entry with the exit code
        let lastEntry = history[0]
        history[0] = RunHistoryEntry(
            scriptPath: lastEntry.scriptPath,
            scriptName: lastEntry.scriptName,
            exitCode: exitCode,
            arguments: lastEntry.arguments
        )

        saveHistory(history)
    }

    func getHistory() -> [RunHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: "runHistory"),
              let history = try? JSONDecoder().decode([RunHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: "runHistory")
    }

    private func saveHistory(_ history: [RunHistoryEntry]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "runHistory")
        }
    }
}

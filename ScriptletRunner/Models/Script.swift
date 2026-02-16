import Foundation

struct Script: Identifiable, Hashable {
    let id: UUID
    let path: String
    let name: String
    var description: String
    var usage: String?
    var arguments: [ScriptArgument]
    var customLabel: String?
    var lastRun: Date?

    init(
        id: UUID = UUID(),
        path: String,
        name: String? = nil,
        description: String = "",
        usage: String? = nil,
        arguments: [ScriptArgument] = [],
        customLabel: String? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name ?? URL(fileURLWithPath: path).lastPathComponent
        self.description = description
        self.usage = usage
        self.arguments = arguments
        self.customLabel = customLabel
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    var displayName: String {
        customLabel ?? name
    }

    var directory: String {
        URL(fileURLWithPath: path).deletingLastPathComponent().path
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    var isExecutable: Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Script, rhs: Script) -> Bool {
        lhs.id == rhs.id
    }
}

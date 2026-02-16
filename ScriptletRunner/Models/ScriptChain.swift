import Foundation

struct ScriptChainStep: Identifiable, Codable, Hashable {
    let id: UUID
    var scriptPath: String
    var scriptName: String
    var arguments: [String: String] // argument id -> value
    var enabledFlags: [String] // argument ids that are enabled
    var continueOnError: Bool

    init(
        id: UUID = UUID(),
        scriptPath: String,
        scriptName: String,
        arguments: [String: String] = [:],
        enabledFlags: [String] = [],
        continueOnError: Bool = false
    ) {
        self.id = id
        self.scriptPath = scriptPath
        self.scriptName = scriptName
        self.arguments = arguments
        self.enabledFlags = enabledFlags
        self.continueOnError = continueOnError
    }
}

struct ScriptChain: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var steps: [ScriptChainStep]
    var createdAt: Date
    var lastRunAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        steps: [ScriptChainStep] = [],
        createdAt: Date = Date(),
        lastRunAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.createdAt = createdAt
        self.lastRunAt = lastRunAt
    }

    var stepCount: Int {
        steps.count
    }
}

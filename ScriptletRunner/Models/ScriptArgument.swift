import Foundation

struct ScriptArgument: Identifiable, Hashable, Codable {
    let id: UUID
    let shortFlag: String?
    let longFlag: String?
    let description: String
    let requiresValue: Bool
    let isPositional: Bool
    let placeholder: String?

    var isEnabled: Bool = false
    var value: String = ""

    init(
        id: UUID = UUID(),
        shortFlag: String? = nil,
        longFlag: String? = nil,
        description: String,
        requiresValue: Bool = false,
        isPositional: Bool = false,
        placeholder: String? = nil
    ) {
        self.id = id
        self.shortFlag = shortFlag
        self.longFlag = longFlag
        self.description = description
        self.requiresValue = requiresValue
        self.isPositional = isPositional
        self.placeholder = placeholder
    }

    var displayName: String {
        if let long = longFlag {
            if let short = shortFlag {
                return "\(short), \(long)"
            }
            return long
        }
        return shortFlag ?? placeholder ?? "argument"
    }

    var flagForCommand: String? {
        longFlag ?? shortFlag
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScriptArgument, rhs: ScriptArgument) -> Bool {
        lhs.id == rhs.id
    }
}

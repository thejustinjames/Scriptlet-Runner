import Foundation

class ScriptParser {

    func parse(scriptPath: String) -> Script {
        let url = URL(fileURLWithPath: scriptPath)
        let name = url.lastPathComponent

        guard let content = try? String(contentsOfFile: scriptPath, encoding: .utf8) else {
            return Script(path: scriptPath, name: name)
        }

        let lines = content.components(separatedBy: .newlines)

        var description = ""
        var usage: String?
        var arguments: [ScriptArgument] = []

        var inOptionsBlock = false
        var inArgumentsBlock = false
        var headerEnded = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip shebang
            if trimmed.hasPrefix("#!") {
                continue
            }

            // Check if we're still in comment header
            if !trimmed.hasPrefix("#") && !trimmed.isEmpty {
                headerEnded = true
            }

            if headerEnded {
                break
            }

            // Remove leading # and trim
            let commentContent = trimmed.hasPrefix("#")
                ? String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                : trimmed

            // Parse Description
            if commentContent.lowercased().hasPrefix("description:") {
                description = String(commentContent.dropFirst(12)).trimmingCharacters(in: .whitespaces)
                inOptionsBlock = false
                inArgumentsBlock = false
                continue
            }

            // First non-empty comment as description fallback
            if description.isEmpty && !commentContent.isEmpty &&
               !commentContent.lowercased().hasPrefix("usage:") &&
               !commentContent.lowercased().hasPrefix("options:") &&
               !commentContent.lowercased().hasPrefix("arguments:") {
                description = commentContent
            }

            // Parse Usage
            if commentContent.lowercased().hasPrefix("usage:") {
                usage = String(commentContent.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                inOptionsBlock = false
                inArgumentsBlock = false
                continue
            }

            // Enter Options block
            if commentContent.lowercased().hasPrefix("options:") {
                inOptionsBlock = true
                inArgumentsBlock = false
                continue
            }

            // Enter Arguments block
            if commentContent.lowercased().hasPrefix("arguments:") {
                inOptionsBlock = false
                inArgumentsBlock = true
                continue
            }

            // Parse option lines
            if inOptionsBlock {
                if let arg = parseOptionLine(commentContent) {
                    arguments.append(arg)
                }
            }

            // Parse positional argument lines
            if inArgumentsBlock {
                if let arg = parsePositionalArgumentLine(commentContent) {
                    arguments.append(arg)
                }
            }
        }

        return Script(
            path: scriptPath,
            name: name,
            description: description,
            usage: usage,
            arguments: arguments
        )
    }

    private func parseOptionLine(_ line: String) -> ScriptArgument? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else { return nil }

        // Match patterns like:
        // -h, --help      Description
        // --verbose       Description
        // -f FILE         Description
        // -o, --output=FILE   Description

        let flagPattern = #"^(-[a-zA-Z])(?:,\s*)?(--[a-zA-Z][-a-zA-Z0-9]*)?\s*(?:=?(\w+))?\s+(.+)$"#
        let longOnlyPattern = #"^(--[a-zA-Z][-a-zA-Z0-9]*)(?:=?(\w+))?\s+(.+)$"#

        if let match = try? NSRegularExpression(pattern: flagPattern).firstMatch(
            in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)
        ) {
            let shortFlag = extractGroup(1, from: match, in: trimmed)
            let longFlag = extractGroup(2, from: match, in: trimmed)
            let placeholder = extractGroup(3, from: match, in: trimmed)
            let desc = extractGroup(4, from: match, in: trimmed) ?? ""

            return ScriptArgument(
                shortFlag: shortFlag,
                longFlag: longFlag,
                description: desc,
                requiresValue: placeholder != nil,
                placeholder: placeholder
            )
        }

        if let match = try? NSRegularExpression(pattern: longOnlyPattern).firstMatch(
            in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)
        ) {
            let longFlag = extractGroup(1, from: match, in: trimmed)
            let placeholder = extractGroup(2, from: match, in: trimmed)
            let desc = extractGroup(3, from: match, in: trimmed) ?? ""

            return ScriptArgument(
                longFlag: longFlag,
                description: desc,
                requiresValue: placeholder != nil,
                placeholder: placeholder
            )
        }

        return nil
    }

    private func parsePositionalArgumentLine(_ line: String) -> ScriptArgument? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else { return nil }

        // Match patterns like:
        // input           Description text
        // <output>        Description text

        let pattern = #"^<?(\w+)>?\s+(.+)$"#

        if let match = try? NSRegularExpression(pattern: pattern).firstMatch(
            in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)
        ) {
            let name = extractGroup(1, from: match, in: trimmed) ?? ""
            let desc = extractGroup(2, from: match, in: trimmed) ?? ""

            return ScriptArgument(
                description: desc,
                requiresValue: true,
                isPositional: true,
                placeholder: name
            )
        }

        return nil
    }

    private func extractGroup(_ index: Int, from match: NSTextCheckingResult, in string: String) -> String? {
        guard index < match.numberOfRanges else { return nil }
        let range = match.range(at: index)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: string) else { return nil }
        return String(string[swiftRange])
    }
}

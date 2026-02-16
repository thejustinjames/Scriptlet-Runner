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
        var choicesFromUsage: [String] = []

        var inOptionsBlock = false
        var inArgumentsBlock = false
        var inChoicesBlock = false
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
                inChoicesBlock = false
                continue
            }

            // First non-empty comment as description fallback
            // Skip decoration lines (=== or ---)
            let isDecoration = commentContent.allSatisfy { $0 == "=" || $0 == "-" || $0 == "#" || $0 == "*" }
            if description.isEmpty && !commentContent.isEmpty && !isDecoration &&
               !commentContent.lowercased().hasPrefix("usage:") &&
               !commentContent.lowercased().hasPrefix("options:") &&
               !commentContent.lowercased().hasPrefix("arguments:") {
                description = commentContent
            }

            // Parse Usage and extract choices like [local|parallel|off]
            if commentContent.lowercased().hasPrefix("usage:") {
                usage = String(commentContent.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                inOptionsBlock = false
                inArgumentsBlock = false
                inChoicesBlock = false

                // Extract choices from usage like [opt1|opt2|opt3]
                if let choices = extractChoicesFromUsage(usage!) {
                    choicesFromUsage = choices
                    inChoicesBlock = true
                }
                continue
            }

            // Parse usage example lines like: ./script.sh --option # description
            if commentContent.contains("./") && commentContent.contains(".sh") {
                if let arg = parseUsageExampleLine(commentContent) {
                    // Only add if we don't already have this option
                    if !arguments.contains(where: { $0.longFlag == arg.longFlag && $0.shortFlag == arg.shortFlag }) {
                        arguments.append(arg)
                    }
                }
                continue
            }

            // Enter Options block
            if commentContent.lowercased().hasPrefix("options:") {
                inOptionsBlock = true
                inArgumentsBlock = false
                inChoicesBlock = false
                continue
            }

            // Enter Arguments block
            if commentContent.lowercased().hasPrefix("arguments:") {
                inOptionsBlock = false
                inArgumentsBlock = true
                inChoicesBlock = false
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

            // Parse choice description lines (name - description or name  description)
            if inChoicesBlock && !choicesFromUsage.isEmpty {
                if let arg = parseChoiceLine(commentContent, validChoices: choicesFromUsage) {
                    arguments.append(arg)
                }
            }
        }

        // If we found choices in usage but no individual args, create one combined choice arg
        if !choicesFromUsage.isEmpty && arguments.isEmpty {
            arguments.append(ScriptArgument(
                description: "Select mode",
                requiresValue: true,
                isPositional: true,
                placeholder: "mode",
                choices: choicesFromUsage
            ))
        }

        // If no arguments found from comments, try parsing script body
        if arguments.isEmpty {
            let bodyArgs = parseScriptBody(lines)
            arguments.append(contentsOf: bodyArgs)
        }

        return Script(
            path: scriptPath,
            name: name,
            description: description,
            usage: usage,
            arguments: arguments
        )
    }

    private func parseScriptBody(_ lines: [String]) -> [ScriptArgument] {
        var arguments: [ScriptArgument] = []
        var foundOptions: Set<String> = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Look for case patterns like: "local"|"parallel"|"off")
            // or "local"|"simulation"|"1")
            if trimmed.contains(")") && (trimmed.contains("\"") || trimmed.contains("'")) {
                let casePattern = #"\"([a-zA-Z0-9_-]+)\""#
                if let regex = try? NSRegularExpression(pattern: casePattern) {
                    let matches = regex.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
                    for match in matches {
                        if let range = Range(match.range(at: 1), in: trimmed) {
                            let option = String(trimmed[range])
                            // Skip numeric options and common non-options
                            if !option.allSatisfy({ $0.isNumber }) &&
                               option != "esac" && option.count > 1 &&
                               !foundOptions.contains(option) {
                                foundOptions.insert(option)
                            }
                        }
                    }
                }
            }

            // Look for echo lines with option descriptions like:
            // echo "  local    - Full local simulation"
            // echo "  --execute # Actually perform the push"
            if trimmed.hasPrefix("echo") && trimmed.contains(" - ") {
                // Pattern: echo "  optionname   - description"
                let echoPattern = #"echo\s+[\"']\s*([a-zA-Z][a-zA-Z0-9_-]*)\s+[-–]\s+(.+?)[\"']"#
                if let regex = try? NSRegularExpression(pattern: echoPattern),
                   let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                    if let nameRange = Range(match.range(at: 1), in: trimmed),
                       let descRange = Range(match.range(at: 2), in: trimmed) {
                        let name = String(trimmed[nameRange])
                        let desc = String(trimmed[descRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'()"))

                        // Filter out things that look like paths or URLs
                        if name.count >= 2 && name.count <= 20 &&
                           !name.contains(".") && !name.contains("/") &&
                           !foundOptions.contains(name) {
                            arguments.append(ScriptArgument(
                                description: desc,
                                requiresValue: false,
                                isPositional: true,
                                placeholder: name
                            ))
                            foundOptions.insert(name)
                        }
                    }
                }
            }
        }

        return arguments
    }

    private func extractChoicesFromUsage(_ usage: String) -> [String]? {
        // Match patterns like [local|parallel|off] or [opt1|opt2]
        let pattern = #"\[([a-zA-Z0-9_]+(?:\|[a-zA-Z0-9_]+)+)\]"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: usage, range: NSRange(usage.startIndex..., in: usage)),
              let range = Range(match.range(at: 1), in: usage) else {
            return nil
        }

        let choicesStr = String(usage[range])
        return choicesStr.components(separatedBy: "|")
    }

    private func parseUsageExampleLine(_ line: String) -> ScriptArgument? {
        // Match patterns like:
        // ./script.sh --execute # Actually perform the push
        // ./script.sh -v        # Verbose mode
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Look for --option or -o followed by description after #
        let pattern = #"\.sh\s+(--?[a-zA-Z][-a-zA-Z0-9]*)\s*(?:#\s*(.+))?$"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }

        let flag = extractGroup(1, from: match, in: trimmed)
        let desc = extractGroup(2, from: match, in: trimmed) ?? ""

        guard let flagStr = flag else { return nil }

        if flagStr.hasPrefix("--") {
            return ScriptArgument(
                longFlag: flagStr,
                description: desc.trimmingCharacters(in: .whitespaces),
                requiresValue: false
            )
        } else {
            return ScriptArgument(
                shortFlag: flagStr,
                description: desc.trimmingCharacters(in: .whitespaces),
                requiresValue: false
            )
        }
    }

    private func parseChoiceLine(_ line: String, validChoices: [String]) -> ScriptArgument? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Match patterns like:
        // local     - Full local simulation
        // local       Full local simulation
        // local  Description text
        let pattern = #"^([a-zA-Z0-9_-]+)\s+[-–]?\s*(.+)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }

        guard let nameRange = Range(match.range(at: 1), in: trimmed),
              let descRange = Range(match.range(at: 2), in: trimmed) else {
            return nil
        }

        let name = String(trimmed[nameRange])
        let desc = String(trimmed[descRange]).trimmingCharacters(in: .whitespaces)

        // Only create argument if name matches one of the valid choices
        guard validChoices.contains(name) else { return nil }

        return ScriptArgument(
            description: desc,
            requiresValue: false,
            isPositional: true,
            placeholder: name,
            choices: nil  // Individual choice, not a picker
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

import SwiftUI
import AppKit

/// Parses ANSI escape codes and converts them to AttributedString
struct ANSIParser {

    // ANSI color codes to SwiftUI colors
    private static let foregroundColors: [Int: Color] = [
        30: Color(nsColor: .black),
        31: Color.red,
        32: Color.green,
        33: Color.yellow,
        34: Color.blue,
        35: Color.purple,
        36: Color.cyan,
        37: Color(nsColor: .white),
        90: Color.gray,
        91: Color.red.opacity(0.8),
        92: Color.green.opacity(0.8),
        93: Color.yellow.opacity(0.8),
        94: Color.blue.opacity(0.8),
        95: Color.purple.opacity(0.8),
        96: Color.cyan.opacity(0.8),
        97: Color(nsColor: .white)
    ]

    private static let backgroundColors: [Int: Color] = [
        40: Color(nsColor: .black),
        41: Color.red,
        42: Color.green,
        43: Color.yellow,
        44: Color.blue,
        45: Color.purple,
        46: Color.cyan,
        47: Color(nsColor: .white),
        100: Color.gray,
        101: Color.red.opacity(0.5),
        102: Color.green.opacity(0.5),
        103: Color.yellow.opacity(0.5),
        104: Color.blue.opacity(0.5),
        105: Color.purple.opacity(0.5),
        106: Color.cyan.opacity(0.5),
        107: Color(nsColor: .white)
    ]

    /// Parse ANSI-encoded string into AttributedString with colors
    static func parse(_ input: String) -> AttributedString {
        // Regex to match ANSI escape sequences
        let ansiPattern = #"\x1B\[([0-9;]*)m"#
        guard let regex = try? NSRegularExpression(pattern: ansiPattern) else {
            return AttributedString(input)
        }

        var result = AttributedString()
        var currentForeground: Color?
        var currentBackground: Color?
        var isBold = false
        var isDim = false
        var isItalic = false
        var isUnderline = false

        var lastEnd = input.startIndex
        let nsString = input as NSString
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            // Get text before this escape sequence
            if let range = Range(match.range, in: input) {
                let textBefore = String(input[lastEnd..<range.lowerBound])
                if !textBefore.isEmpty {
                    var attributedText = AttributedString(textBefore)

                    // Apply current styles
                    if let fg = currentForeground {
                        attributedText.foregroundColor = isDim ? fg.opacity(0.6) : fg
                    }
                    if let bg = currentBackground {
                        attributedText.backgroundColor = bg
                    }
                    if isBold {
                        attributedText.font = .system(.body, design: .monospaced).bold()
                    }
                    if isItalic {
                        attributedText.font = .system(.body, design: .monospaced).italic()
                    }
                    if isUnderline {
                        attributedText.underlineStyle = .single
                    }

                    result += attributedText
                }
                lastEnd = range.upperBound
            }

            // Parse the escape codes
            if match.numberOfRanges > 1,
               let codeRange = Range(match.range(at: 1), in: input) {
                let codes = String(input[codeRange])
                let codeValues = codes.split(separator: ";").compactMap { Int($0) }

                for code in codeValues {
                    switch code {
                    case 0:
                        // Reset all
                        currentForeground = nil
                        currentBackground = nil
                        isBold = false
                        isDim = false
                        isItalic = false
                        isUnderline = false
                    case 1:
                        isBold = true
                    case 2:
                        isDim = true
                    case 3:
                        isItalic = true
                    case 4:
                        isUnderline = true
                    case 22:
                        isBold = false
                        isDim = false
                    case 23:
                        isItalic = false
                    case 24:
                        isUnderline = false
                    case 30...37, 90...97:
                        currentForeground = foregroundColors[code]
                    case 39:
                        currentForeground = nil
                    case 40...47, 100...107:
                        currentBackground = backgroundColors[code]
                    case 49:
                        currentBackground = nil
                    default:
                        break
                    }
                }
            }
        }

        // Add remaining text after last escape sequence
        if lastEnd < input.endIndex {
            let remaining = String(input[lastEnd...])
            if !remaining.isEmpty {
                var attributedText = AttributedString(remaining)
                if let fg = currentForeground {
                    attributedText.foregroundColor = isDim ? fg.opacity(0.6) : fg
                }
                if let bg = currentBackground {
                    attributedText.backgroundColor = bg
                }
                result += attributedText
            }
        }

        // If no ANSI codes found, return plain attributed string
        if result.characters.isEmpty && !input.isEmpty {
            return AttributedString(input)
        }

        return result
    }

    /// Strip ANSI codes from string (for plain text operations)
    static func stripANSI(_ input: String) -> String {
        let ansiPattern = #"\x1B\[[0-9;]*m"#
        guard let regex = try? NSRegularExpression(pattern: ansiPattern) else {
            return input
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: "")
    }
}

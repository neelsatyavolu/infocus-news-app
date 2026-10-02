import Foundation

/// Turns the small amount of HTML WordPress returns (titles, excerpts,
/// story bodies) into plain text without a web view.
enum HTMLText {
    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "ndash": "–", "mdash": "—", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
        "hellip": "…", "bull": "•", "middot": "·", "copy": "©", "reg": "®", "trade": "™",
    ]

    /// Decodes `&amp;`, `&#039;`, `&#8217;`, `&#x2019;` …; unknown entities stay as written.
    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var result = ""
        var rest = text[...]
        while let amp = rest.firstIndex(of: "&") {
            result += rest[..<amp]
            let after = rest[rest.index(after: amp)...]
            if let semi = after.prefix(10).firstIndex(of: ";"),
               let decoded = decode(String(after[..<semi])) {
                result += decoded
                rest = after[after.index(after: semi)...]
            } else {
                result += "&"
                rest = after
            }
        }
        return result + rest
    }

    private static func decode(_ entity: String) -> String? {
        if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
            return UInt32(entity.dropFirst(2), radix: 16).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }
        if entity.hasPrefix("#") {
            return UInt32(entity.dropFirst()).flatMap(Unicode.Scalar.init).map { String(Character($0)) }
        }
        return named[entity.lowercased()]
    }

    /// Tags removed, entities decoded, whitespace collapsed.
    static func plain(_ html: String) -> String {
        let noTags = html
            .replacingOccurrences(of: "<br\\s*/?>", with: " ", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return decodeEntities(noTags)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Paragraphs of a story body: split on block ends and `<br>`, scripts,
    /// styles and embeds dropped, empty paragraphs skipped.
    static func paragraphs(_ html: String) -> [String] {
        let cleaned = html
            .replacingOccurrences(of: "<(script|style|iframe|figure)[^>]*>[\\s\\S]*?</\\1>", with: "",
                                  options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "</(p|div|h[1-6]|li|blockquote)>|<br\\s*/?>", with: "\n",
                                  options: [.regularExpression, .caseInsensitive])
        return cleaned
            .components(separatedBy: "\n")
            .map(plain)
            .filter { !$0.isEmpty }
    }
}

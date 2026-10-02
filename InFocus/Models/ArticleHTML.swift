import Foundation

/// A WordPress page body as native blocks: headings, paragraphs and list
/// items with bold and links kept. Images, embeds and styling are dropped
/// (the site's old logo art doesn't belong in the app).
enum ArticleBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(AttributedString)
    case bullet(AttributedString)
}

enum ArticleHTML {
    static func blocks(_ html: String) -> [ArticleBlock] {
        var builder = Builder()
        let cleaned = html.replacingOccurrences(of: "<(script|style|figure|iframe)[^>]*>[\\s\\S]*?</\\1>", with: "",
                                                options: [.regularExpression, .caseInsensitive])
        let tag = try! NSRegularExpression(pattern: "<(/?)([a-zA-Z0-9]+)([^>]*)>")
        let text = cleaned as NSString
        var cursor = 0
        for match in tag.matches(in: cleaned, range: NSRange(location: 0, length: text.length)) {
            builder.text(text.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            builder.tag(name: text.substring(with: match.range(at: 2)).lowercased(),
                        closing: match.range(at: 1).length > 0,
                        attributes: text.substring(with: match.range(at: 3)))
            cursor = match.range.location + match.range.length
        }
        builder.text(text.substring(from: cursor))
        builder.flush()
        return builder.blocks
    }

    /// Every `mailto:` address in the page, in order, without duplicates.
    static func emails(_ html: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: #"mailto:([^"'?>\s]+)"#, options: .caseInsensitive)
        let text = html as NSString
        var seen: [String] = []
        for match in regex.matches(in: html, range: NSRange(location: 0, length: text.length)) {
            let email = HTMLText.decodeEntities(text.substring(with: match.range(at: 1)))
            if !seen.contains(email) { seen.append(email) }
        }
        return seen
    }

    private enum Kind { case paragraph, heading(Int), bullet }

    private struct Builder {
        var blocks: [ArticleBlock] = []
        private var kind: Kind = .paragraph
        private var current = AttributedString()
        private var bold = 0
        private var links: [URL?] = []

        mutating func text(_ raw: String) {
            let decoded = HTMLText.decodeEntities(raw.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression))
            guard !decoded.isEmpty else { return }
            // No leading space at the start of a block or after a line break.
            let last = current.characters.last
            let piece = (last == nil || last == "\n" || last == " ") && decoded.hasPrefix(" ")
                ? String(decoded.dropFirst()) : decoded
            guard !piece.isEmpty else { return }
            var run = AttributedString(piece)
            if bold > 0 { run.inlinePresentationIntent = .stronglyEmphasized }
            if let link = links.last ?? nil { run.link = link }
            current += run
        }

        mutating func tag(name: String, closing: Bool, attributes: String) {
            switch name {
            case "p", "div", "blockquote", "ul", "ol", "section", "article":
                flush()
                if closing { kind = .paragraph }
            case "h1", "h2", "h3", "h4", "h5", "h6":
                flush()
                kind = closing ? .paragraph : .heading(Int(name.dropFirst()) ?? 3)
            case "li":
                flush()
                kind = closing ? .paragraph : .bullet
            case "br":
                let trimmed = String(current.characters).trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { trimTrailingSpace(); current += AttributedString("\n") }
            case "strong", "b":
                bold = max(0, bold + (closing ? -1 : 1))
            case "a":
                if closing { _ = links.popLast() } else { links.append(Self.href(attributes)) }
            default:
                break
            }
        }

        mutating func flush() {
            trimTrailingSpace()
            while current.characters.last == "\n" { current.characters.removeLast() }
            defer { current = AttributedString() }
            let plain = String(current.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !plain.isEmpty else { return }
            switch kind {
            case .heading(let level): blocks.append(.heading(level: level, text: plain))
            case .bullet: blocks.append(.bullet(current))
            case .paragraph: blocks.append(.paragraph(current))
            }
        }

        private mutating func trimTrailingSpace() {
            while current.characters.last == " " { current.characters.removeLast() }
        }

        /// http(s) and mailto links only.
        private static func href(_ attributes: String) -> URL? {
            guard let range = attributes.range(of: #"href\s*=\s*["']([^"']+)["']"#, options: .regularExpression) else { return nil }
            let value = attributes[range].split(separator: "=", maxSplits: 1)[1]
                .trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            guard let url = URL(string: HTMLText.decodeEntities(value)),
                  ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") else { return nil }
            return url
        }
    }
}

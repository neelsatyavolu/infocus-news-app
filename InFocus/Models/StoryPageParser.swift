import Foundation

/// The story's video only appears in the rendered story page (the SNO theme
/// keeps it out of the REST content), so the app reads it from the page.
enum StoryPageParser {
    /// The first YouTube video inside the story (headline to share icons),
    /// ignoring the site's header/footer YouTube links.
    static func videoID(in html: String) -> String? {
        // The class names also appear in the site's stylesheet, above the header.
        // A bare string search would treat that CSS as the story and could play a
        // header video or miss the story video entirely.
        let start = classMarker("sno-story-headline", in: html, from: html.startIndex)
            ?? html.range(of: "sno-story-headline")?.lowerBound
            ?? html.startIndex
        let end = classMarker("sno-story-social-icons", in: html, from: start)
            ?? html.range(of: "sno-story-social-icons", range: start..<html.endIndex)?.lowerBound
            ?? html.endIndex
        let story = html[start..<end]
        let pattern = #"(?:youtube(?:-nocookie)?\.com/(?:embed/|watch\?v=|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let text = String(story)
        let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        return match.flatMap { Range($0.range(at: 1), in: text) }.map { String(text[$0]) }
    }

    /// Start of a `class="…name…"` attribute, matching a whole class token.
    private static func classMarker(_ name: String, in html: String, from start: String.Index) -> String.Index? {
        guard start < html.endIndex,
              let regex = try? NSRegularExpression(pattern: #"class\s*=\s*(["'])([^"']*)\1"#) else { return nil }
        let range = NSRange(start..<html.endIndex, in: html)
        for match in regex.matches(in: html, range: range) {
            guard let valueRange = Range(match.range(at: 2), in: html),
                  html[valueRange].split(whereSeparator: \.isWhitespace).contains(where: { $0 == name }),
                  let found = Range(match.range, in: html) else { continue }
            return found.lowerBound
        }
        return nil
    }
}

import Foundation

/// The story's video only appears in the rendered story page (the SNO theme
/// keeps it out of the REST content), so the app reads it from the page.
enum StoryPageParser {
    /// The first YouTube video inside the story (headline to share icons),
    /// ignoring the site's header/footer YouTube links.
    static func videoID(in html: String) -> String? {
        let start = html.range(of: "sno-story-headline")?.lowerBound ?? html.startIndex
        let end = html.range(of: "sno-story-social-icons", range: start..<html.endIndex)?.lowerBound ?? html.endIndex
        let story = html[start..<end]
        let pattern = #"(?:youtube(?:-nocookie)?\.com/(?:embed/|watch\?v=|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let text = String(story)
        let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        return match.flatMap { Range($0.range(at: 1), in: text) }.map { String(text[$0]) }
    }
}

import Testing
import Foundation
@testable import InFocus

struct WordPressTests {
    private func stories() throws -> [Story] {
        try JSONDecoder().decode([WPPost].self, from: Fixture.data("posts")).map(Story.init)
    }

    @Test func flattensAPost() throws {
        let story = try stories()[0]
        #expect(story.title == "Breaking ‘News’ & More")
        #expect(story.categories.map(\.slug) == ["news"])
        #expect(story.imageURL?.lastPathComponent == "large.png")
        #expect(story.thumbnailURL?.lastPathComponent == "ml.png")
        #expect(story.paragraphs.isEmpty)
        #expect(story.date == ISODate.parse("2026-09-25T16:02:54Z"))
    }

    @Test func bylinesFollowTheSiteOrderNotTheTermOrder() throws {
        let story = try stories()[0]
        #expect(story.bylines == ["Abby Example", "Otto Example", "Sage Example"])
        #expect(story.byline == "Abby Example, Otto Example, and Sage Example")
    }

    @Test func toleratesAForbiddenMediaEmbed() throws {
        let story = try stories()[1]
        #expect(story.imageURL == nil)
        #expect(story.bylines.isEmpty)
        #expect(story.byline == nil)
        #expect(story.excerpt == "Short summary…")
        #expect(story.paragraphs == ["First paragraph with a link.", "Second paragraph."])
    }

    @Test func joinsBylines() {
        #expect(Bylines.join(["Abby"]) == "Abby")
        #expect(Bylines.join(["Abby", "Otto"]) == "Abby and Otto")
    }

    @Test func decodesEntities() {
        #expect(HTMLText.decodeEntities("Paly&#039;s &amp; Gunn &#x2019;26 &mdash; &unknown; & done") == "Paly's & Gunn ’26 — &unknown; & done")
        #expect(HTMLText.plain("<p>Hi&nbsp;<b>there</b></p>\n") == "Hi there")
    }

    @Test func findsTheStoryVideoInsideTheStoryOnly() {
        let page = """
        <header><a href="https://www.youtube.com/watch?v=HEADERxxxxx">YouTube</a></header>
        <h1 class="sno-story-headline">Title</h1>
        <div class="sno-story-video-area"><iframe src='https://www.youtube.com/embed/0SHOaN11vKM?si=abc'></iframe></div>
        <div class="sno-story-social-icons"></div>
        <footer><iframe src="https://www.youtube.com/embed/FOOTERxxxxx"></iframe></footer>
        """
        #expect(StoryPageParser.videoID(in: page) == "0SHOaN11vKM")
    }

    @Test func noVideoInTheStory() {
        let page = """
        <a href="https://youtube.com/c/InFocusNews">Channel</a>
        <h1 class="sno-story-headline">Title</h1><div class="sno-story-photo-area"></div>
        <div class="sno-story-social-icons"></div>
        <iframe src="https://www.youtube.com/embed/FOOTERxxxxx"></iframe>
        """
        #expect(StoryPageParser.videoID(in: page) == nil)
    }

    @Test func recognisesOtherYouTubeLinkShapes() {
        #expect(StoryPageParser.videoID(in: #"<p class="sno-story-headline">x</p><a href="https://youtu.be/abcDEF12345">"#) == "abcDEF12345")
        #expect(StoryPageParser.videoID(in: #"sno-story-headline <iframe src="https://www.youtube-nocookie.com/embed/abcDEF_1-45">"#) == "abcDEF_1-45")
    }
}

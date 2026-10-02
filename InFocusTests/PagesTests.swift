import Testing
import Foundation
@testable import InFocus

struct ArticleHTMLTests {
    private let about = """
    <p><strong>Example Policy</strong><br />
    A student publication</p>
    <h3>What We Make</h3>
    <h4>The Show</h4>
    <p>Shows run on Wednesday &amp; Friday. Email <a href="mailto:producers@example.edu">producers@example.edu</a>.</p>
    <ul>
    <li><strong>Abby Example</strong>, Producer: runs things.</li>
    <li><strong>Otto Example</strong> &#8211; Reporter</li>
    </ul>
    <p><img src="https://example.edu/logo.png" alt="logo"></p>
    <p>&nbsp;</p>
    <script>alert(1)</script>
    """

    @Test func turnsHTMLIntoBlocks() {
        let blocks = ArticleHTML.blocks(about)
        #expect(blocks.count == 6)
        #expect(plain(blocks[0]) == "Example Policy\nA student publication")
        #expect(blocks[1] == .heading(level: 3, text: "What We Make"))
        #expect(blocks[2] == .heading(level: 4, text: "The Show"))
        #expect(plain(blocks[3]) == "Shows run on Wednesday & Friday. Email producers@example.edu.")
        #expect(plain(blocks[4]) == "Abby Example, Producer: runs things.")
        #expect(plain(blocks[5]) == "Otto Example – Reporter")
    }

    @Test func keepsBoldAndLinks() throws {
        let blocks = ArticleHTML.blocks(about)
        guard case .bullet(let bullet) = blocks[4] else { Issue.record("not a bullet"); return }
        let boldRun = try #require(bullet.runs.first)
        #expect(String(bullet[boldRun.range].characters) == "Abby Example")
        #expect(boldRun.inlinePresentationIntent == .stronglyEmphasized)

        guard case .paragraph(let paragraph) = blocks[3] else { Issue.record("not a paragraph"); return }
        let link = paragraph.runs.first { $0.link != nil }
        #expect(link?.link == URL(string: "mailto:producers@example.edu"))
        #expect(link.map { String(paragraph[$0.range].characters) } == "producers@example.edu")
    }

    @Test func dropsUnsafeLinks() {
        let blocks = ArticleHTML.blocks(#"<p><a href="javascript:alert(1)">Tap</a></p>"#)
        guard case .paragraph(let text) = blocks.first else { Issue.record("no paragraph"); return }
        #expect(text.runs.allSatisfy { $0.link == nil })
    }

    @Test func findsEmails() {
        let html = #"<a href="mailto:producers@example.edu">a</a> <a href='mailto:adviser@example.edu'>b</a> <a href="mailto:producers@example.edu">c</a>"#
        #expect(ArticleHTML.emails(html) == ["producers@example.edu", "adviser@example.edu"])
    }

    private func plain(_ block: ArticleBlock) -> String {
        switch block {
        case .heading(_, let text): text
        case .paragraph(let text), .bullet(let text): String(text.characters)
        }
    }
}

struct StaffTests {
    private let page = """
    <h1><span class="staff-page-title">2026-2027 Staff</span></h1>
    <ul><li><a href="https://infocusnews.tv/staff/?schoolyear=2026-2027">2026-2027</a></li>
    <li><a href="https://infocusnews.tv/staff/?schoolyear=2025-2026">2025-2026</a></li></ul>
    <div class="profile_grid_wrap">
    <div class='grid-widget-tile grid-staff-tile toggle-staff-group' data-group="">
      <a href="https://infocusnews.tv/staff_name/abby-example/">
      <img src='https://example.edu/abby-960x1200.jpg' alt='' />
      <div class='topstorycat'><span class="blockscat">Executive Producer, Operations &amp; Production</span></div>
      <h3 class="staffmembername">Abby Example</h3></a></div>
    <div class='grid-widget-tile grid-staff-tile toggle-staff-group' data-group="">
      <a href="https://infocusnews.tv/staff_name/otto-example/">
      <img src='https://example.edu/otto.jpg' alt='' />
      <div class='topstorycat'><span class="blockscat">Reporter</span></div>
      <h3 class="staffmembername">Otto Example</h3></a></div>
    </div>
    """

    @Test func parsesTheStaffPage() {
        let directory = StaffPageParser.directory(from: page)
        #expect(directory.year == "2026-2027")
        #expect(directory.years == ["2026-2027", "2025-2026"])
        #expect(directory.members.map(\.name) == ["Abby Example", "Otto Example"])
        #expect(directory.members[0].role == "Executive Producer, Operations & Production")
        #expect(directory.members[0].slug == "abby-example")
        #expect(directory.members[0].photoURL?.lastPathComponent == "abby-960x1200.jpg")
        #expect(directory.members[1].year == "2026-2027")
    }

    @Test func emptyPageHasNoStaff() {
        #expect(StaffPageParser.directory(from: "<html></html>").members.isEmpty)
    }

    @Test func matchesProfilesByPersonAndYear() throws {
        let json = """
        [
          { "content": { "rendered": "<p>Old bio.</p>" },
            "_embedded": { "wp:term": [ [ { "id": 7, "name": "Abby Example", "slug": "abby-example", "taxonomy": "staff_name" } ],
                                        [ { "id": 92, "name": "2024-2025", "slug": "2024-2025", "taxonomy": "staff_year" } ] ] } },
          { "content": { "rendered": "<p>Current bio.</p>" },
            "_embedded": { "wp:term": [ [ { "id": 7, "name": "Abby Example", "slug": "abby-example", "taxonomy": "staff_name" } ],
                                        [ { "id": 150, "name": "2026-2027", "slug": "2026-2027", "taxonomy": "staff_year" } ] ] } },
          { "content": { "rendered": "" },
            "_embedded": { "wp:term": [ [ { "id": 9, "name": "Otto Example", "slug": "otto-example", "taxonomy": "staff_name" } ] ] } }
        ]
        """
        let profiles = try JSONDecoder().decode([WPStaffProfile].self, from: Data(json.utf8))
        let current = try #require(WPStaffProfile.match(profiles, slug: "abby-example", year: "2026-2027"))
        #expect(current.staffTermID == 7)
        #expect(current.bio.count == 1)
        if case .paragraph(let text) = current.bio.first { #expect(String(text.characters) == "Current bio.") }

        let fallback = try #require(WPStaffProfile.match(profiles, slug: "abby-example", year: "2030-2031"))
        if case .paragraph(let text) = fallback.bio.first { #expect(String(text.characters) == "Old bio.") }

        let noBio = try #require(WPStaffProfile.match(profiles, slug: "otto-example", year: "2026-2027"))
        #expect(noBio.bio.isEmpty)
        #expect(WPStaffProfile.match(profiles, slug: "sage-example", year: "2026-2027") == nil)
    }
}

struct SocialTests {
    @Test func everyLinkIsHTTPS() {
        #expect(SocialLink.all.map(\.network) == ["Instagram", "YouTube", "TikTok", "X", "Website"])
        #expect(SocialLink.all.allSatisfy { $0.url.scheme == "https" })
        #expect(AppConfig.privacyURL.absoluteString == "https://infocuspaly.com/privacy")
    }
}

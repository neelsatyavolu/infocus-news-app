import Testing
import Foundation
@testable import InFocus

struct LinkedTextTests {
    @Test func findsWebAddressesWithAndWithoutAScheme() {
        let text = "Apply at https://example.org/apply or bit.ly/palyscholarships by Friday."
        let urls = LinkedText.links(in: text).map(\.url.absoluteString)
        #expect(urls == ["https://example.org/apply", "http://bit.ly/palyscholarships"])
    }

    @Test func findsEmailsAndPhoneNumbers() {
        let text = "Questions? Email club@example.org or call (650) 555-0142."
        let urls = LinkedText.links(in: text).map(\.url.absoluteString)
        #expect(urls == ["mailto:club@example.org", "tel:6505550142"])
    }

    @Test func linksOnlyTheMatchedWords() {
        let attributed = LinkedText.attributed("Sign up at example.org today.")
        let linked = attributed.runs.filter { $0.link != nil }.map { String(attributed[$0.range].characters) }
        #expect(linked == ["example.org"])
    }

    @Test func leavesPlainAnnouncementsAlone() {
        #expect(LinkedText.links(in: "Club Fair is Thursday in the Quad.").isEmpty)
    }
}

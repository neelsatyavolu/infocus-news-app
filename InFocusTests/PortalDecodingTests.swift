import Testing
import Foundation
@testable import InFocus

struct PortalDecodingTests {
    @Test func decodesShowsFeed() throws {
        let feed = try ISODate.decoder.decode(Envelope<ShowsFeed>.self, from: Fixture.data("shows")).data
        #expect(feed.latest?.videoId == "abcDEF12345")
        #expect(feed.seasons.map(\.number) == [31, 30])
        #expect(feed.seasons[0].shows.count == 2)
        #expect(feed.upcomingShowDates.first == "2026-10-07")

        let latest = try #require(feed.latest)
        #expect(latest.displayTitle == "Friday, September 25")
        #expect(latest.duration == "12:22")
        #expect(latest.publishedAt == ISODate.parse("2026-09-25T15:30:00Z"))
    }

    @Test func showWithoutDateFallsBackToTitle() throws {
        let feed = try ISODate.decoder.decode(Envelope<ShowsFeed>.self, from: Fixture.data("shows")).data
        let show = feed.seasons[0].shows[1]
        #expect(show.showDate == nil)
        #expect(show.thumbnailUrl == nil)
        #expect(show.displayTitle == "Wednesday, September 23, 2026")
    }

    @Test func decodesLiveFeed() throws {
        let feed = try ISODate.decoder.decode(Envelope<LiveFeed>.self, from: Fixture.data("live")).data
        #expect(feed.live.first?.isLive == true)
        #expect(feed.recent.first?.isLive == false)
        #expect(feed.upcoming.first?.location == "Performing Arts Center")
        #expect(feed.upcoming.first?.videoId == nil)
    }

    @Test func errorEnvelopeBecomesTheMessage() throws {
        let body = Data(#"{"error":{"message":"End date cannot be before the start date."}}"#.utf8)
        let response = HTTPURLResponse(url: URL(string: "https://example.edu")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        #expect(throws: APIError.server(status: 400, message: "End date cannot be before the start date.")) {
            try PortalClient.check(body, response)
        }
    }

    @Test func serverErrorsWithoutBodyAreWorded() {
        #expect(APIError.server(status: 503, message: nil).errorDescription?.contains("trouble") == true)
        #expect(APIError.offline.errorDescription?.contains("offline") == true)
    }

    @Test func durationLabels() {
        #expect(Duration.label(59) == "0:59")
        #expect(Duration.label(742) == "12:22")
        #expect(Duration.label(3725) == "1:02:05")
    }

    @Test func seriesPrefixIsStripped() {
        #expect(Show.strippingSeries("InFocus News | Friday, September 4th, 2026") == "Friday, September 4th, 2026")
        #expect(Show.strippingSeries("InFocusNews | Wednesday") == "Wednesday")
        #expect(Show.strippingSeries("Gas Prices") == "Gas Prices")
        #expect(Show.strippingSeries("Water Polo | Senior Night") == "Water Polo | Senior Night")
    }
}

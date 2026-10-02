import Testing
import Foundation
@testable import InFocus

struct ShowDateTests {
    @Test func parsesAndFormatsPacificDays() throws {
        let date = try #require(ShowDate.parse("2026-09-25"))
        #expect(ShowDate.long(date) == "Friday, September 25")
        #expect(ShowDate.short(date) == "Fri, Sep 25")
        #expect(ShowDate.key(date) == "2026-09-25")
        #expect(ShowDate.parse("2026-9-25") == nil)
        #expect(ShowDate.parse("soon") == nil)
    }

    @Test func showWindowIsConsecutiveShowDays() {
        let dates = ["2026-10-07", "2026-10-09", "2026-10-14", "2026-10-16", "2026-10-21"]
        #expect(ShowDate.window(from: "2026-10-09", in: dates, limit: 4) == ["2026-10-09", "2026-10-14", "2026-10-16", "2026-10-21"])
        #expect(ShowDate.window(from: "2026-10-21", in: dates, limit: 4) == ["2026-10-21"])
        #expect(ShowDate.window(from: "2026-12-25", in: dates, limit: 4).isEmpty)
    }

    @Test func isoDatesWithAndWithoutFractions() {
        #expect(ISODate.parse("2026-09-25T15:30:00.000Z") == ISODate.parse("2026-09-25T15:30:00Z"))
        #expect(ISODate.parse("yesterday") == nil)
    }
}

struct AnnouncementTests {
    private func valid() -> AnnouncementSubmission {
        AnnouncementSubmission(email: " abby@example.edu ", name: " Abby ", submitterKind: .palyStudent, runOn: .both,
                               announcement: " Club fair is Thursday. ", startDate: "2026-10-07", endDate: "2026-10-09",
                               policyAgreed: true, mediaLink: "  ", moreInfo: nil)
    }

    @Test func validFormHasNoProblem() {
        #expect(valid().problem == nil)
    }

    @Test func reportsTheFirstProblem() {
        var form = valid()
        form.email = "abby@"
        #expect(form.problem == "Enter a valid email.")
        form = valid()
        form.endDate = "2026-10-01"
        #expect(form.problem == "The last show can't be before the first.")
        form = valid()
        form.mediaLink = "flyer.example.edu"
        #expect(form.problem?.hasPrefix("Media link") == true)
        form = valid()
        form.policyAgreed = false
        #expect(form.problem?.contains("policy") == true)
    }

    @Test func payloadIsTrimmedAndDropsBlankOptionals() throws {
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(valid().payload)) as? [String: Any]
        #expect(json?["email"] as? String == "abby@example.edu")
        #expect(json?["name"] as? String == "Abby")
        #expect(json?["announcement"] as? String == "Club fair is Thursday.")
        #expect(json?["submitterKind"] as? String == "PALY_STUDENT")
        #expect(json?["runOn"] as? String == "BOTH")
        #expect(json?["policyAgreed"] as? Bool == true)
        #expect(json?["mediaLink"] == nil)
    }
}

struct PushTests {
    @Test func tokenHex() {
        #expect(PushManager.hex(Data([0x00, 0xAB, 0x10, 0xFF])) == "00ab10ff")
    }

    @Test func destinationsFromPayloads() {
        let show: [AnyHashable: Any] = ["aps": ["alert": ["title": "New show", "body": "Friday"]], "kind": "show", "videoId": "abcDEF12345"]
        #expect(Destination.from(push: show) == .show(videoId: "abcDEF12345", title: "Friday"))
        #expect(Destination.from(push: ["kind": "story", "postId": "2619"]) == .story(id: 2619))
        #expect(Destination.from(push: ["kind": "story", "postId": 2619]) == .story(id: 2619))
        #expect(Destination.from(push: ["kind": "live", "videoId": "LIVE0000001"]) == .live(videoId: "LIVE0000001", title: nil))
    }

    @Test func rejectsBadPayloads() {
        #expect(Destination.from(push: ["kind": "show", "videoId": "../../etc"]) == nil)
        #expect(Destination.from(push: ["kind": "story"]) == nil)
        #expect(Destination.from(push: ["url": "https://example.edu"]) == nil)
    }

    @Test func videoIDs() {
        #expect(YouTube.isVideoID("abcDEF_1-45"))
        #expect(!YouTube.isVideoID("short"))
        #expect(!YouTube.isVideoID("abcDEF12345?"))
        #expect(!YouTube.isVideoID("abcdéf12345"))
    }
}

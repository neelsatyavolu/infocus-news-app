import Foundation
import Observation

/// The announcement form's state, sending and result.
@MainActor @Observable
final class AnnounceModel {
    enum Status: Equatable { case editing, sending, sent }

    var form: AnnouncementSubmission
    private(set) var status: Status = .editing
    private(set) var error: String?
    /// Upcoming show dates (`YYYY-MM-DD`) to choose from; empty means free dates.
    private(set) var showDates: [String] = []

    private let client: PortalClient

    init(name: String, email: String, client: PortalClient = .shared) {
        self.client = client
        form = AnnouncementSubmission(email: email, name: name, submitterKind: .palyStudent, runOn: .infocusOnly,
                                      announcement: "", startDate: ShowDate.key(.now), endDate: ShowDate.key(.now),
                                      policyAgreed: false)
    }

    /// Last shows the end picker allows: the start and up to three more show days.
    var endChoices: [String] {
        ShowDate.window(from: form.startDate, in: showDates, limit: AnnouncementSubmission.maxShowDays)
    }

    func useShowDates(_ dates: [String]) {
        guard showDates.isEmpty, !dates.isEmpty else { return }
        showDates = dates
        if !dates.contains(form.startDate) { setStart(dates[0]) }
    }

    func setStart(_ date: String) {
        form.startDate = date
        if form.endDate.isEmpty || form.endDate < date || (!showDates.isEmpty && !endChoices.contains(form.endDate)) {
            form.endDate = date
        }
    }

    func submit() async -> Bool {
        if let problem = form.problem {
            error = problem
            return false
        }
        error = nil
        status = .sending
        do {
            try await client.submit(form)
            status = .sent
            return true
        } catch {
            self.error = (error as? APIError)?.status == 429
                ? "Too many announcements from this network. Try again in an hour."
                : Loadable<Void>.message(for: error)
            status = .editing
            return false
        }
    }

    /// Clears the announcement but keeps who's sending it.
    func startOver() {
        form.announcement = ""
        form.mediaLink = nil
        form.moreInfo = nil
        form.policyAgreed = false
        if let first = showDates.first { setStart(first) }
        error = nil
        status = .editing
    }
}

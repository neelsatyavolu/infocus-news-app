import Foundation
import Observation

/// The staff directory for one school year, plus bios loaded once.
@MainActor @Observable
final class StaffModel {
    private(set) var directory: Loadable<StaffDirectory> = .idle
    /// Every school year the site offers (kept when switching years).
    private(set) var years: [String] = []
    private(set) var selectedYear: String?
    private var profiles: [WPStaffProfile]?
    private let client: WordPressClient

    init(client: WordPressClient = .shared) {
        self.client = client
    }

    func load(year: String? = nil, force: Bool = false) async {
        if !force, year == selectedYear, directory.value != nil || directory.isLoading { return }
        if year != selectedYear || directory.value == nil { directory = .loading }
        do {
            let loaded = try await client.staffDirectory(year: year)
            if !loaded.years.isEmpty { years = loaded.years }
            selectedYear = loaded.year.isEmpty ? year : loaded.year
            directory = .loaded(loaded)
        } catch is CancellationError {
            if directory.isLoading { directory = .idle }
        } catch {
            directory = .failed(Loadable<StaffDirectory>.message(for: error))
        }
    }

    /// Bio and byline id for a person (nil when they have no profile).
    func profile(for member: StaffMember) async throws -> StaffProfile? {
        if profiles == nil { profiles = try await client.staffProfiles() }
        return WPStaffProfile.match(profiles ?? [], slug: member.slug, year: member.year)
    }
}

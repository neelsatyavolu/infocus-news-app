import Foundation
import Observation

/// Shows (all seasons) and each show's announcements, shared across tabs.
@MainActor @Observable
final class ShowsStore {
    private(set) var feed: Loadable<ShowsFeed> = .idle
    private(set) var announcements: [String: Loadable<[String]>] = [:]
    private let client: PortalClient
    private var loadGeneration = 0
    private var announcementGeneration: [String: Int] = [:]

    init(client: PortalClient = .shared) {
        self.client = client
    }

    /// Loads once; `force` (pull to refresh) reloads but keeps showing the old feed meanwhile.
    /// A slower request can't replace a newer one, or turn a successful refresh into an error.
    func load(force: Bool = false) async {
        if !force, feed.value != nil || feed.isLoading { return }
        loadGeneration += 1
        let generation = loadGeneration
        if feed.value == nil { feed = .loading }
        do {
            let loaded = try await client.shows().removingDuplicateEpisodes()
            guard generation == loadGeneration || feed.value == nil else { return }
            feed = .loaded(loaded)
        } catch is CancellationError {
            guard generation == loadGeneration else { return }
            if feed.isLoading { feed = .idle }
        } catch {
            guard generation == loadGeneration else { return }
            if feed.value == nil { feed = .failed(Loadable<ShowsFeed>.message(for: error)) }
        }
    }

    func show(videoId: String) -> Show? {
        guard let feed = feed.value else { return nil }
        if feed.latest?.videoId == videoId { return feed.latest }
        return feed.seasons.lazy.flatMap(\.shows).first { $0.videoId == videoId }
    }

    func announcements(for showDate: String) -> Loadable<[String]> {
        announcements[showDate] ?? .idle
    }

    func loadAnnouncements(for showDate: String, force: Bool = false) async {
        if !force, let state = announcements[showDate], state.value != nil || state.isLoading { return }
        let generation = (announcementGeneration[showDate] ?? 0) + 1
        announcementGeneration[showDate] = generation
        if announcements[showDate]?.value == nil { announcements[showDate] = .loading }
        do {
            let items = try await client.announcements(for: showDate).announcements
            guard announcementGeneration[showDate] == generation else { return }
            announcements[showDate] = .loaded(items)
        } catch let error as APIError where error.status == 404 {
            guard announcementGeneration[showDate] == generation else { return }
            announcements[showDate] = .loaded([])
        } catch is CancellationError {
            guard announcementGeneration[showDate] == generation else { return }
            if announcements[showDate]?.isLoading == true { announcements[showDate] = nil }
        } catch {
            guard announcementGeneration[showDate] == generation else { return }
            if announcements[showDate]?.value == nil {
                announcements[showDate] = .failed(Loadable<[String]>.message(for: error))
            }
        }
    }
}

/// Live now, upcoming and replays.
@MainActor @Observable
final class LiveStore {
    private(set) var feed: Loadable<LiveFeed> = .idle
    private let client: PortalClient
    private var loadGeneration = 0

    init(client: PortalClient = .shared) {
        self.client = client
    }

    var liveNow: [LiveVideo] { feed.value?.live ?? [] }

    func load(force: Bool = false) async {
        if !force, feed.value != nil || feed.isLoading { return }
        loadGeneration += 1
        let generation = loadGeneration
        if feed.value == nil { feed = .loading }
        do {
            let loaded = try await client.live()
            guard generation == loadGeneration || feed.value == nil else { return }
            feed = .loaded(loaded)
        } catch is CancellationError {
            guard generation == loadGeneration else { return }
            if feed.isLoading { feed = .idle }
        } catch {
            guard generation == loadGeneration else { return }
            if feed.value == nil { feed = .failed(Loadable<LiveFeed>.message(for: error)) }
        }
    }
}

import Foundation
import Observation

/// Shows (all seasons) and each show's announcements, shared across tabs.
@MainActor @Observable
final class ShowsStore {
    private(set) var feed: Loadable<ShowsFeed> = .idle
    private(set) var announcements: [String: Loadable<[String]>] = [:]
    private let client: PortalClient

    init(client: PortalClient = .shared) {
        self.client = client
    }

    /// Loads once; `force` (pull to refresh) reloads but keeps showing the old feed meanwhile.
    func load(force: Bool = false) async {
        if !force, feed.value != nil || feed.isLoading { return }
        if feed.value == nil { feed = .loading }
        do {
            feed = .loaded(try await client.shows())
        } catch is CancellationError {
            if feed.isLoading { feed = .idle }
        } catch {
            if feed.value == nil || !force { feed = .failed(Loadable<ShowsFeed>.message(for: error)) }
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
        announcements[showDate] = .loading
        do {
            announcements[showDate] = .loaded(try await client.announcements(for: showDate).announcements)
        } catch let error as APIError where error.status == 404 {
            announcements[showDate] = .loaded([])
        } catch is CancellationError {
            announcements[showDate] = nil
        } catch {
            announcements[showDate] = .failed(Loadable<[String]>.message(for: error))
        }
    }
}

/// Live now, upcoming and replays.
@MainActor @Observable
final class LiveStore {
    private(set) var feed: Loadable<LiveFeed> = .idle
    private let client: PortalClient

    init(client: PortalClient = .shared) {
        self.client = client
    }

    var liveNow: [LiveVideo] { feed.value?.live ?? [] }

    func load(force: Bool = false) async {
        if !force, feed.value != nil || feed.isLoading { return }
        if feed.value == nil { feed = .loading }
        do {
            feed = .loaded(try await client.live())
        } catch is CancellationError {
            if feed.isLoading { feed = .idle }
        } catch {
            if feed.value == nil || !force { feed = .failed(Loadable<LiveFeed>.message(for: error)) }
        }
    }
}

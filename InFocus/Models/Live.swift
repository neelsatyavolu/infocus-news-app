import Foundation

/// `GET /api/public/live`.
struct LiveFeed: Decodable, Sendable, Equatable {
    let live: [LiveVideo]
    let upcoming: [UpcomingStream]
    let recent: [LiveVideo]

    static let empty = LiveFeed(live: [], upcoming: [], recent: [])
}

/// A livestream on the InFocus channel: on now, or a replay.
struct LiveVideo: Codable, Sendable, Equatable, Hashable, Identifiable {
    let videoId: String
    let title: String
    let thumbnailUrl: URL?
    let startedAt: Date?
    let endedAt: Date?

    var id: String { videoId }
    var isLive: Bool { startedAt != nil && endedAt == nil }
}

/// A scheduled public livestream (games, concerts, ceremonies).
struct UpcomingStream: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let startsAt: Date
    let location: String?
    let videoId: String?
}

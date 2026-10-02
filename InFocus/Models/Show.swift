import Foundation

/// `GET /api/public/shows`.
struct ShowsFeed: Decodable, Sendable, Equatable {
    let latest: Show?
    let seasons: [Season]
    let upcomingShowDates: [String]
}

struct Season: Decodable, Sendable, Equatable, Identifiable {
    let number: Int
    let title: String
    let playlistId: String
    let shows: [Show]

    var id: Int { number }
}

/// One full InFocus News episode on YouTube.
struct Show: Codable, Sendable, Equatable, Hashable, Identifiable {
    let videoId: String
    let title: String
    /// `YYYY-MM-DD` (Pacific), when the title names the show's date.
    let showDate: String?
    let publishedAt: Date?
    let thumbnailUrl: URL?
    let durationSeconds: Int?

    var id: String { videoId }

    /// "Friday, September 25" from the show date, else the title without the
    /// "InFocus News |" prefix.
    var displayTitle: String {
        if let date = showDate.flatMap(ShowDate.parse) { return ShowDate.long(date) }
        return Self.strippingSeries(title)
    }

    var dateLabel: String? {
        if let date = showDate.flatMap(ShowDate.parse) { return ShowDate.short(date) }
        return publishedAt.map(ShowDate.short)
    }

    var duration: String? { durationSeconds.map(Duration.label) }
    var watchURL: URL { YouTube.watchURL(videoId) }

    static func strippingSeries(_ title: String) -> String {
        let parts = title.components(separatedBy: "|")
        guard parts.count > 1, parts[0].lowercased().replacingOccurrences(of: " ", with: "").hasPrefix("infocus") else {
            return title
        }
        return parts.dropFirst().joined(separator: "|").trimmingCharacters(in: .whitespaces)
    }
}

/// `GET /api/public/shows/{date}/announcements`.
struct ShowAnnouncements: Decodable, Sendable, Equatable {
    let showDate: String
    let announcements: [String]
}

enum Duration {
    /// 742 → "12:22"; 3725 → "1:02:05".
    static func label(_ seconds: Int) -> String {
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

enum YouTube {
    static func watchURL(_ videoId: String) -> URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
    }

    static func thumbnailURL(_ videoId: String) -> URL {
        URL(string: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg")!
    }

    static let channelURL = URL(string: "https://www.youtube.com/@infocusnews")!

    /// YouTube ids are 11 characters of [A-Za-z0-9_-].
    static func isVideoID(_ value: String) -> Bool {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        return value.count == 11 && value.allSatisfy(allowed.contains)
    }
}

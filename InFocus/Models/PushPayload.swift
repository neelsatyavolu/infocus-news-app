import Foundation

/// Where a notification (or any in-app link) leads.
enum Destination: Hashable, Identifiable, Sendable {
    case show(videoId: String, title: String?)
    case story(id: Int)
    case live(videoId: String, title: String?)

    var id: String {
        switch self {
        case .show(let videoId, _): "show-\(videoId)"
        case .story(let id): "story-\(id)"
        case .live(let videoId, _): "live-\(videoId)"
        }
    }

    /// Reads a news push: `kind` + `videoId` / `postId` beside `aps`.
    static func from(push userInfo: [AnyHashable: Any]) -> Destination? {
        let alert = (userInfo["aps"] as? [String: Any])?["alert"] as? [String: Any]
        let body = alert?["body"] as? String
        let videoId = (userInfo["videoId"] as? String).flatMap { YouTube.isVideoID($0) ? $0 : nil }
        switch userInfo["kind"] as? String {
        case "show": return videoId.map { .show(videoId: $0, title: body) }
        case "live": return videoId.map { .live(videoId: $0, title: body) }
        case "story":
            let raw = userInfo["postId"]
            let id = (raw as? Int) ?? (raw as? String).flatMap(Int.init)
            return id.map { .story(id: $0) }
        default: return nil
        }
    }
}

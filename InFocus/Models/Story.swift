import Foundation

/// A story from infocusnews.tv, flattened from the WordPress post.
struct Story: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: Int
    let title: String
    let excerpt: String
    /// Body paragraphs (most video stories have none).
    let paragraphs: [String]
    let date: Date
    let link: URL
    let imageURL: URL?
    let thumbnailURL: URL?
    let categories: [StoryCategory]
    /// Reporters in the site's byline order.
    let bylines: [String]

    var byline: String? { bylines.isEmpty ? nil : Bylines.join(bylines) }
    var primaryCategory: StoryCategory? { categories.first }
}

struct StoryCategory: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

enum Bylines {
    /// "A", "A and B", "A, B, and C" (the site's style).
    static func join(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) and \(names[1])"
        default: return names.dropLast().joined(separator: ", ") + ", and " + names.last!
        }
    }
}

/// One page of stories plus how many pages exist (`X-WP-TotalPages`).
struct StoryPage: Sendable {
    let stories: [Story]
    let totalPages: Int
}

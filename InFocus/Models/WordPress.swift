import Foundation

/// The parts of a WordPress REST post (`_embed=wp:featuredmedia,wp:term`) the app uses.
struct WPPost: Decodable, Sendable {
    struct Rendered: Decodable, Sendable { let rendered: String }

    let id: Int
    let dateGmt: String
    let link: URL
    let title: Rendered
    let excerpt: Rendered?
    let content: Rendered?
    let categories: [Int]?
    let staffName: [Int]?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id, link, title, excerpt, content, categories
        case dateGmt = "date_gmt"
        case staffName = "staff_name"
        case embedded = "_embedded"
    }

    struct Embedded: Decodable, Sendable {
        let featuredMedia: [Media]?
        let terms: [[Term]]?

        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
            case terms = "wp:term"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Missing or private media embeds come back as error objects; skip them.
            featuredMedia = try? container.decodeIfPresent([Media].self, forKey: .featuredMedia)
            terms = try? container.decodeIfPresent([[Term]].self, forKey: .terms)
        }
    }

    struct Media: Decodable, Sendable {
        struct Details: Decodable, Sendable {
            struct Size: Decodable, Sendable { let sourceUrl: URL
                enum CodingKeys: String, CodingKey { case sourceUrl = "source_url" } }
            let sizes: [String: Size]?
        }

        let sourceUrl: URL?
        let mediaDetails: Details?

        enum CodingKeys: String, CodingKey {
            case sourceUrl = "source_url"
            case mediaDetails = "media_details"
        }

        func url(preferring names: [String]) -> URL? {
            names.lazy.compactMap { mediaDetails?.sizes?[$0]?.sourceUrl }.first ?? sourceUrl
        }
    }

    struct Term: Decodable, Sendable {
        let id: Int
        let name: String
        let slug: String
        let taxonomy: String
    }
}

/// `GET /wp/v2/categories`.
struct WPCategory: Decodable, Sendable {
    let id: Int
    let name: String
    let slug: String
    let count: Int
}

/// `GET /wp/v2/staff_name`.
struct WPStaffTerm: Decodable, Sendable {
    let id: Int
}

extension Story {
    init(_ post: WPPost) {
        let terms = post.embedded?.terms?.flatMap { $0 } ?? []
        let categoryTerms = terms.filter { $0.taxonomy == "category" }
        let staff = Dictionary(terms.filter { $0.taxonomy == "staff_name" }.map { ($0.id, $0.name) },
                               uniquingKeysWith: { first, _ in first })
        let media = post.embedded?.featuredMedia?.first

        self.init(
            id: post.id,
            title: HTMLText.plain(post.title.rendered),
            excerpt: HTMLText.plain(post.excerpt?.rendered ?? ""),
            paragraphs: HTMLText.paragraphs(post.content?.rendered ?? ""),
            date: ISODate.parse(post.dateGmt + "Z") ?? .distantPast,
            link: post.link,
            imageURL: media?.url(preferring: ["large", "1536x1536", "full"]),
            thumbnailURL: media?.url(preferring: ["medium_large", "medium", "large"]),
            categories: categoryTerms.map { StoryCategory(id: $0.id, name: HTMLText.plain($0.name), slug: $0.slug) },
            bylines: (post.staffName ?? []).compactMap { staff[$0] }
        )
    }
}

import Foundation

/// One person on the staff page for a school year.
struct StaffMember: Hashable, Identifiable, Sendable {
    let name: String
    let role: String
    /// Profile slug (`/staff_name/<slug>/`): matches the person's byline term.
    let slug: String
    let photoURL: URL?
    let year: String

    var id: String { "\(year)/\(slug)" }
    var profileURL: URL { URL(string: "https://infocusnews.tv/staff_name/\(slug)/")! }
}

/// The staff page (`/staff/?schoolyear=…`): the people in the site's order
/// and every school year it offers.
struct StaffDirectory: Equatable, Sendable {
    let year: String
    let members: [StaffMember]
    /// Newest first, as the site lists them.
    let years: [String]
}

/// Bio and byline id from a `staff_profile` post.
struct StaffProfile: Equatable, Sendable {
    let bio: [ArticleBlock]
    let staffTermID: Int?
}

enum StaffPageParser {
    static func directory(from html: String) -> StaffDirectory {
        let year = firstMatch(#"staff-page-title">\s*(\d{4}-\d{4})"#, in: html) ?? ""
        var years: [String] = []
        for found in allMatches(#"schoolyear=(\d{4}-\d{4})"#, in: html) where !years.contains(found) {
            years.append(found)
        }
        let tiles = html.components(separatedBy: "grid-staff-tile").dropFirst()
        let members = tiles.compactMap { tile -> StaffMember? in
            guard let slug = firstMatch(#"staff_name/([A-Za-z0-9_-]+)/"#, in: tile),
                  let name = firstMatch(#"staffmembername">([\s\S]*?)</"#, in: tile).map(HTMLText.plain),
                  !name.isEmpty else { return nil }
            let role = firstMatch(#"blockscat">([\s\S]*?)</span>"#, in: tile).map(HTMLText.plain) ?? ""
            let photo = firstMatch(#"<img[^>]*src=['"]([^'"]+)['"]"#, in: tile).flatMap { URL(string: HTMLText.decodeEntities($0)) }
            return StaffMember(name: name, role: role, slug: slug, photoURL: photo, year: year)
        }
        return StaffDirectory(year: year, members: members, years: years.sorted(by: >))
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        allMatches(pattern, in: text, limit: 1).first
    }

    private static func allMatches(_ pattern: String, in text: String, limit: Int = .max) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            .prefix(limit)
            .map { ns.substring(with: $0.range(at: 1)) }
    }
}

/// `GET /wp/v2/staff_profile?_embed=wp:term`.
struct WPStaffProfile: Decodable, Sendable {
    let content: WPPost.Rendered?
    let embedded: WPPost.Embedded?

    enum CodingKeys: String, CodingKey {
        case content
        case embedded = "_embedded"
    }

    var personSlug: String? { terms(in: "staff_name").first?.slug }
    var personTermID: Int? { terms(in: "staff_name").first?.id }
    var years: [String] { terms(in: "staff_year").map(\.name) }

    private func terms(in taxonomy: String) -> [WPPost.Term] {
        (embedded?.terms ?? []).flatMap { $0 }.filter { $0.taxonomy == taxonomy }
    }

    /// The profile for that person and year; their newest one if none matches the year.
    static func match(_ profiles: [WPStaffProfile], slug: String, year: String) -> StaffProfile? {
        let theirs = profiles.filter { $0.personSlug == slug }
        guard let best = theirs.first(where: { $0.years.contains(year) }) ?? theirs.first else { return nil }
        return StaffProfile(bio: ArticleHTML.blocks(best.content?.rendered ?? ""), staffTermID: best.personTermID)
    }
}

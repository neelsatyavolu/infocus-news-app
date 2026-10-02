import Foundation

/// Site pages (About, Contact) and the staff directory.
extension WordPressClient {
    struct Page: Sendable {
        let title: String
        let html: String
        let link: URL
    }

    private struct WPPage: Decodable {
        let title: WPPost.Rendered
        let content: WPPost.Rendered
        let link: URL
    }

    func page(slug: String) async throws -> Page {
        let (data, response) = try await request("wp-json/wp/v2/pages", [
            URLQueryItem(name: "slug", value: slug),
            URLQueryItem(name: "_fields", value: "title,content,link"),
        ])
        try PortalClient.check(data, response)
        guard let page = try? JSONDecoder().decode([WPPage].self, from: data).first else {
            throw APIError.server(status: 404, message: "This page isn't available right now.")
        }
        return Page(title: HTMLText.plain(page.title.rendered), html: page.content.rendered, link: page.link)
    }

    /// The staff page for a school year (`nil`: the site's current year).
    func staffDirectory(year: String?) async throws -> StaffDirectory {
        var components = URLComponents(url: site.appending(path: "staff/"), resolvingAgainstBaseURL: false)!
        if let year { components.queryItems = [URLQueryItem(name: "schoolyear", value: year)] }
        var request = URLRequest(url: components.url!)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await HTTP.data(for: request)
        try PortalClient.check(data, response)
        return StaffPageParser.directory(from: String(decoding: data, as: UTF8.self))
    }

    /// Every staff profile (bios), all years.
    func staffProfiles() async throws -> [WPStaffProfile] {
        var all: [WPStaffProfile] = []
        var page = 1
        var total = 1
        repeat {
            let (data, response) = try await request("wp-json/wp/v2/staff_profile", [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "_embed", value: "wp:term"),
                URLQueryItem(name: "_fields", value: "content,_links,_embedded"),
            ])
            try PortalClient.check(data, response)
            guard let batch = try? JSONDecoder().decode([WPStaffProfile].self, from: data) else { throw APIError.badResponse }
            all += batch
            total = min(Int(response.value(forHTTPHeaderField: "X-WP-TotalPages") ?? "") ?? 1, 10)
            page += 1
        } while page <= total
        return all
    }
}

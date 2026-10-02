import Foundation

/// infocusnews.tv's WordPress REST API, plus the story pages themselves.
struct WordPressClient: Sendable {
    let site: URL

    static let shared = WordPressClient(site: AppConfig.newsSiteURL)

    /// The site's firewall turns away requests that don't look like a browser.
    static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1 InFocusApp/\(AppConfig.version)"

    private static let postFields =
        "id,date_gmt,link,title,excerpt,content,categories,staff_name,_links,_embedded"

    struct Query: Sendable, Equatable {
        var category: Int?
        var search: String?
        var staff: [Int] = []
        var include: [Int] = []
        var perPage = 20
    }

    func stories(_ query: Query, page: Int) async throws -> StoryPage {
        var items = [
            URLQueryItem(name: "per_page", value: String(query.perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "_embed", value: "wp:featuredmedia,wp:term"),
            URLQueryItem(name: "_fields", value: Self.postFields),
        ]
        if let category = query.category { items.append(URLQueryItem(name: "categories", value: String(category))) }
        if let search = query.search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
        if !query.staff.isEmpty { items.append(URLQueryItem(name: "staff_name", value: Self.ids(query.staff))) }
        if !query.include.isEmpty { items.append(URLQueryItem(name: "include", value: Self.ids(query.include))) }

        let (data, response) = try await get("wp-json/wp/v2/posts", items)
        // WordPress answers 400 for a page past the end.
        if response.statusCode == 400, page > 1 { return StoryPage(stories: [], totalPages: page - 1) }
        try PortalClient.check(data, response)
        let posts = try decode([WPPost].self, data)
        let total = Int(response.value(forHTTPHeaderField: "X-WP-TotalPages") ?? "") ?? page
        return StoryPage(stories: posts.map(Story.init), totalPages: total)
    }

    func story(id: Int) async throws -> Story {
        let page = try await stories(Query(include: [id], perPage: 1), page: 1)
        guard let story = page.stories.first else { throw APIError.server(status: 404, message: "That story isn't available anymore.") }
        return story
    }

    func categories() async throws -> [StoryCategory] {
        let (data, response) = try await get("wp-json/wp/v2/categories", [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "_fields", value: "id,name,slug,count"),
        ])
        try PortalClient.check(data, response)
        return try decode([WPCategory].self, data)
            .filter { $0.count > 0 && !Self.hiddenCategorySlugs.contains($0.slug) }
            .sorted { $0.count > $1.count }
            .map { StoryCategory(id: $0.id, name: HTMLText.plain($0.name), slug: $0.slug) }
    }

    /// Reporter ids whose name matches, for searching by byline.
    func reporters(matching name: String) async throws -> [Int] {
        let (data, response) = try await get("wp-json/wp/v2/staff_name", [
            URLQueryItem(name: "search", value: name),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "_fields", value: "id"),
        ])
        try PortalClient.check(data, response)
        return try decode([WPStaffTerm].self, data).map(\.id)
    }

    /// The YouTube video embedded in the story page, if there is one.
    func videoID(for story: Story) async throws -> String? {
        var request = URLRequest(url: story.link)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await HTTP.data(for: request)
        try PortalClient.check(data, response)
        return StoryPageParser.videoID(in: String(decoding: data, as: UTF8.self))
    }

    static let hiddenCategorySlugs: Set<String> = ["uncategorized", "showcase", "archives", "equipment"]

    // MARK: Plumbing

    private func get(_ path: String, _ items: [URLQueryItem]) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: site.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = items
        var request = URLRequest(url: components.url!)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await HTTP.data(for: request)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        do { return try JSONDecoder().decode(type, from: data) } catch { throw APIError.badResponse }
    }

    private static func ids(_ values: [Int]) -> String { values.map(String.init).joined(separator: ",") }
}

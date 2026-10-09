import Foundation
import Observation

/// The story list: category filter, search (title or reporter) and paging.
@MainActor @Observable
final class StoriesModel {
    private(set) var categories: [StoryCategory] = []
    private(set) var stories: [Story] = []
    private(set) var state: Loadable<Void> = .idle
    private(set) var loadingMore = false
    var category: StoryCategory? {
        didSet { if category != oldValue { Task { await reload() } } }
    }
    private(set) var query = ""

    private var page = 0
    private var totalPages = 1
    private var generation = 0
    /// What the stories currently on screen were loaded for.
    private var loadedCategory: StoryCategory?
    private var loadedQuery = ""
    private let client: WordPressClient

    init(client: WordPressClient = .shared) {
        self.client = client
    }

    var canLoadMore: Bool { page < totalPages && !loadingMore && state.value != nil }

    func start() async {
        guard case .idle = state else { return }
        async let categories: Void = loadCategories()
        await reload()
        await categories
    }

    func search(_ text: String) async {
        let text = text.trimmed
        guard text != query else { return }
        // Wait for typing to pause before changing what the list is showing.
        // A newer search cancels this one; committing early would leave the
        // field and the results disagreeing if this task is cancelled.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        query = text
        await reload()
    }

    func reload() async {
        generation += 1
        let current = generation
        // Same category and search: a refresh. Anything else must not keep
        // showing the previous list (Sports stories under the News chip).
        let refreshing = category == loadedCategory && query == loadedQuery && state.value != nil
        if !refreshing {
            page = 0
            totalPages = 1
            stories = []
            state = .loading
        }
        do {
            let first = try await fetch(page: 1)
            guard current == generation else { return }
            stories = first.stories
            page = 1
            totalPages = first.totalPages
            loadedCategory = category
            loadedQuery = query
            state = .loaded(())
        } catch is CancellationError {
            if current == generation, state.isLoading { state = .idle }
        } catch {
            guard current == generation else { return }
            if refreshing { return }
            stories = []
            state = .failed(Loadable<Void>.message(for: error))
        }
    }

    func loadMore(after story: Story) async {
        guard story.id == stories.last?.id, canLoadMore else { return }
        let current = generation
        loadingMore = true
        defer { loadingMore = false }
        do {
            let next = try await fetch(page: page + 1)
            guard current == generation else { return }
            let known = Set(stories.map(\.id))
            stories += next.stories.filter { !known.contains($0.id) }
            page += 1
            totalPages = next.totalPages
        } catch {
            // The list stays; scrolling to the end again retries.
        }
    }

    private func fetch(page: Int) async throws -> StoryPage {
        var base = WordPressClient.Query(category: category?.id)
        guard !query.isEmpty else { return try await client.stories(base, page: page) }

        base.search = query
        guard page == 1 else { return try await client.stories(base, page: page) }
        // First page of a search: title/text matches plus the reporter's own stories.
        async let byText = client.stories(base, page: 1)
        async let reporterIDs = (try? client.reporters(matching: query)) ?? []
        let ids = await reporterIDs
        let text = try await byText
        guard !ids.isEmpty else { return text }
        let byReporter = (try? await client.stories(.init(category: category?.id, staff: ids), page: 1))?.stories ?? []
        let merged = Dictionary((text.stories + byReporter).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            .values.sorted { $0.date > $1.date }
        return StoryPage(stories: merged, totalPages: text.totalPages)
    }

    private func loadCategories() async {
        guard categories.isEmpty else { return }
        categories = (try? await client.categories()) ?? []
    }
}

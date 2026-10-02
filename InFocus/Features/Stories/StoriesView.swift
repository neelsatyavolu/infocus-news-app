import SwiftUI

/// Every story on infocusnews.tv: category chips, search, endless scroll.
struct StoriesView: View {
    @State private var model = StoriesModel()
    @State private var searchText = ""
    @State private var searchPresented = false
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack {
            list
                .brandBackground()
                .navigationTitle("Stories")
                .navigationDestination(for: Story.self) { StoryDetailView(story: $0) }
                .navigationDestination(for: SavedRoute.self) { _ in SavedView() }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: SavedRoute()) {
                            Image(systemName: "bookmark")
                        }
                        .accessibilityLabel("Saved stories")
                    }
                }
                .searchable(text: $searchText, isPresented: $searchPresented, prompt: "Search stories or reporters")
                .task(id: searchText) { await model.search(searchText) }
                .task { await model.start() }
                .refreshable { await model.reload() }
                .onChange(of: router.focusStorySearch, initial: true) { _, focus in
                    if focus { searchPresented = true; router.focusStorySearch = false }
                }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    results.padding(.horizontal, Brand.gutter)
                } header: {
                    CategoryBar(categories: model.categories, selected: model.category) { model.category = $0 }
                }
            }
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder private var results: some View {
        switch model.state {
        case .idle, .loading:
            SkeletonList(rows: 6).padding(.top, 8)
        case .failed(let message):
            ErrorStateView(title: "Couldn't load stories", message: message) {
                Task { await model.reload() }
            }
        case .loaded where model.stories.isEmpty:
            EmptyStateView(title: model.query.isEmpty ? "No stories here yet" : "No matches",
                           message: model.query.isEmpty ? "Try another category." : "Try a different word or a reporter's name.")
        case .loaded:
            ForEach(model.stories) { story in
                NavigationLink(value: story) { StoryRow(story: story) }
                    .buttonStyle(.plain)
                    .task { await model.loadMore(after: story) }
                Divider().overlay(Brand.line)
            }
            if model.loadingMore {
                ProgressView().frame(maxWidth: .infinity).padding()
            }
        }
    }
}

struct SavedRoute: Hashable {}

/// "All" plus the site's categories that have stories.
private struct CategoryBar: View {
    let categories: [StoryCategory]
    let selected: StoryCategory?
    let select: (StoryCategory?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All", selected: selected == nil) { select(nil) }
                ForEach(categories) { category in
                    Chip(title: category.name, selected: selected == category) { select(category) }
                }
            }
            .padding(.horizontal, Brand.gutter)
            .padding(.vertical, 10)
        }
        .background(Brand.background)
    }
}

/// Thumbnail, category, headline, byline and date.
struct StoryRow: View {
    let story: Story

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Thumbnail(url: story.thumbnailURL).frame(width: 128)
            VStack(alignment: .leading, spacing: 4) {
                if let category = story.primaryCategory {
                    Eyebrow(category.name, size: 10)
                }
                Text(story.title)
                    .font(.lexend(16, .semibold, relativeTo: .headline))
                    .foregroundStyle(Brand.text)
                    .lineLimit(3)
                StoryMeta(story: story)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Reporters on one line, the date (data, so mono) under it.
struct StoryMeta: View {
    let story: Story
    var lineLimit = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let byline = story.byline {
                Text(byline)
                    .font(.small)
                    .foregroundStyle(Brand.secondary)
                    .lineLimit(lineLimit)
            }
            Text(story.date.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.mono(12))
                .foregroundStyle(Brand.muted)
        }
    }
}

import SwiftUI

/// Live banner, the latest show with its announcements, the newest stories
/// and a way to get an announcement on the show.
struct HomeView: View {
    @Environment(ShowsStore.self) private var shows
    @Environment(LiveStore.self) private var live
    @Environment(Router.self) private var router
    @State private var latestStories: Loadable<[Story]> = .idle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(live.liveNow) { video in
                        NavigationLink(value: video) { LiveBanner(video: video) }.buttonStyle(.plain)
                    }
                    LatestShowSection()
                    storiesSection
                    AnnounceCallout()
                }
                .padding(Brand.gutter)
                .padding(.bottom, 16)
            }
            .brandBackground()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("Wordmark").resizable().scaledToFit().frame(height: 26)
                        .accessibilityLabel("InFocus")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.focusStorySearch = true
                        router.tab = .stories
                    } label: { Image(systemName: "magnifyingglass") }
                    .accessibilityLabel("Search stories")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Show.self) { ShowDetailView(show: $0) }
            .navigationDestination(for: Story.self) { StoryDetailView(story: $0) }
            .navigationDestination(for: LiveVideo.self) { LivePlayerView(video: $0) }
            .navigationDestination(for: AnnounceRoute.self) { _ in AnnounceView() }
            .task { await loadAll(force: false) }
            .refreshable { await loadAll(force: true) }
        }
    }

    @ViewBuilder private var storiesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Latest stories", actionTitle: "All stories") { router.tab = .stories }
            switch latestStories {
            case .idle, .loading:
                SkeletonList(rows: 3)
            case .failed(let message):
                ErrorStateView(title: "Couldn't load stories", message: message) {
                    Task { await loadStories(force: true) }
                }
            case .loaded(let stories):
                ForEach(stories) { story in
                    NavigationLink(value: story) { StoryRow(story: story) }.buttonStyle(.plain)
                    if story.id != stories.last?.id { Divider().overlay(Brand.line) }
                }
            }
        }
    }

    private func loadAll(force: Bool) async {
        async let showFeed: Void = shows.load(force: force)
        async let liveFeed: Void = live.load(force: force)
        async let stories: Void = loadStories(force: force)
        _ = await (showFeed, liveFeed, stories)
    }

    private func loadStories(force: Bool) async {
        if !force, latestStories.value != nil { return }
        if latestStories.value == nil { latestStories = .loading }
        do {
            let page = try await WordPressClient.shared.stories(.init(perPage: 5), page: 1)
            latestStories = .loaded(page.stories)
        } catch is CancellationError {
            if latestStories.isLoading { latestStories = .idle }
        } catch {
            if latestStories.value == nil { latestStories = .failed(Loadable<[Story]>.message(for: error)) }
        }
    }
}

/// The newest show, big, with what was announced on it.
private struct LatestShowSection: View {
    @Environment(ShowsStore.self) private var shows

    var body: some View {
        switch shows.feed {
        case .idle, .loading:
            VStack(alignment: .leading, spacing: 0) {
                Skeleton().aspectRatio(16 / 9, contentMode: .fit)
                Skeleton(height: 84).padding(.top, 2)
            }
        case .failed(let message):
            ErrorStateView(title: "Couldn't load the latest show", message: message) {
                Task { await shows.load(force: true) }
            }
        case .loaded(let feed):
            if let show = feed.latest {
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink(value: show) {
                        VStack(alignment: .leading, spacing: 0) {
                            Thumbnail(url: show.thumbnailUrl)
                                .overlay { PlayBadge() }
                                .overlay(alignment: .bottomTrailing) {
                                    if let duration = show.duration { Tag(text: duration, mono: true).padding(8) }
                                }
                            Nameplate(eyebrow: "Latest show", title: show.displayTitle, subtitle: "InFocus News")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Plays the latest show")
                    if let date = show.showDate {
                        AnnouncementsRecap(showDate: date, title: "Announced on this show", limit: 4)
                            .task { await shows.loadAnnouncements(for: date) }
                    }
                }
            }
        }
    }
}

/// A slim live strip at the very top while a stream is on.
private struct LiveBanner: View {
    let video: LiveVideo

    var body: some View {
        HStack(spacing: 12) {
            LiveTag()
            Text(video.title)
                .font(.lexend(15, .semibold, relativeTo: .headline))
                .foregroundStyle(Brand.text)
                .lineLimit(2)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Brand.muted)
        }
        .card(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live now: \(video.title)")
    }
}

struct AnnounceRoute: Hashable {}

/// "Have news for the show?"
private struct AnnounceCallout: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Get on the show")
            Text("Have news for Paly?")
                .headline(.h3)
            Text("Clubs, teams and teachers can send an announcement for InFocus News to read on air.")
                .font(.small)
                .foregroundStyle(Brand.secondary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink(value: AnnounceRoute()) {
                Text("Submit an announcement")
            }
            .buttonStyle(.brandPrimary)
            .padding(.top, 4)
        }
        .card()
    }
}

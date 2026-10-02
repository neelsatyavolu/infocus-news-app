import SwiftUI

/// The five tabs, the first-run welcome and anything opened from a notification.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            ShowsView()
                .tabItem { Label("Shows", systemImage: "play.rectangle") }
                .tag(AppTab.shows)
            StoriesView()
                .tabItem { Label("Stories", systemImage: "newspaper") }
                .tag(AppTab.stories)
            LiveView()
                .tabItem { Label("Live", systemImage: "dot.radiowaves.left.and.right") }
                .tag(AppTab.live)
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(AppTab.more)
        }
        .sheet(item: $router.presented) { destination in
            NavigationStack {
                DestinationView(destination: destination)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { router.presented = nil }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { !preferences.onboarded },
                                              set: { if !$0 { preferences.onboarded = true } })) {
            WelcomeView()
        }
    }
}

/// A show, story or stream opened by id (notifications).
struct DestinationView: View {
    let destination: Destination
    @Environment(ShowsStore.self) private var shows

    var body: some View {
        switch destination {
        case .show(let videoId, let title):
            ShowDetailView(show: shows.show(videoId: videoId) ?? Show.placeholder(videoId: videoId, title: title))
                .task { await shows.load() }
        case .live(let videoId, let title):
            LivePlayerView(video: LiveVideo(videoId: videoId, title: title ?? "InFocus Live",
                                            thumbnailUrl: nil, startedAt: .now, endedAt: nil))
        case .story(let id):
            StoryLoaderView(storyID: id)
        }
    }
}

extension Show {
    /// Enough to play a show we only know by id (a notification before the feed loads).
    static func placeholder(videoId: String, title: String?) -> Show {
        Show(videoId: videoId, title: title ?? "InFocus News", showDate: nil, publishedAt: nil,
             thumbnailUrl: YouTube.thumbnailURL(videoId), durationSeconds: nil)
    }
}

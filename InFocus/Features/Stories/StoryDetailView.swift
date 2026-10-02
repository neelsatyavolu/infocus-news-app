import SwiftUI

/// One story: its video (or photo), headline, byline and any text.
struct StoryDetailView: View {
    let story: Story
    @Environment(SavedStore.self) private var saved
    @State private var video: Loadable<String?> = .idle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                media
                VStack(alignment: .leading, spacing: 12) {
                    if let category = story.primaryCategory { Eyebrow(category.name) }
                    Text(story.title)
                        .headline(.h1, tracking: -0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    StoryMeta(story: story, lineLimit: 3)
                    Rectangle().fill(Brand.fill).frame(width: 48, height: 4).padding(.vertical, 4)
                    storyText
                    actions.padding(.top, 8)
                }
                .padding(Brand.gutter)
                .frame(maxWidth: 720, alignment: .leading)
            }
        }
        .brandBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saved.toggle(story)
                } label: {
                    Image(systemName: saved.contains(story) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(saved.contains(story) ? "Remove from saved" : "Save for later")
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: story.link, subject: Text(story.title)) { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Share")
            }
        }
        .task(id: story.id) { await loadVideo() }
    }

    @ViewBuilder private var media: some View {
        switch video {
        case .loaded(let id?):
            YouTubePlayer(videoId: id)
        case .idle, .loading:
            Thumbnail(url: story.imageURL).overlay { ProgressView().tint(Brand.softWhite) }
        default:
            Thumbnail(url: story.imageURL)
        }
    }

    @ViewBuilder private var storyText: some View {
        let paragraphs = story.paragraphs.isEmpty && !story.excerpt.isEmpty ? [story.excerpt] : story.paragraphs
        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
            Text(paragraph)
                .font(.lexend(17, .regular, relativeTo: .body))
                .lineSpacing(5)
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if case .loaded(let id?) = video {
                Link(destination: YouTube.watchURL(id)) {
                    Label("Open in YouTube", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.brandSecondary)
            }
            Link(destination: story.link) {
                Label("Open on infocusnews.tv", systemImage: "safari")
            }
            .buttonStyle(.brandSecondary)
        }
    }

    private func loadVideo() async {
        guard case .idle = video else { return }
        video = .loading
        do {
            video = .loaded(try await WordPressClient.shared.videoID(for: story))
        } catch is CancellationError {
            video = .idle
        } catch {
            video = .failed(Loadable<String?>.message(for: error))
        }
    }
}

/// A story opened by id (a notification): fetch, then show.
struct StoryLoaderView: View {
    let storyID: Int
    @State private var state: Loadable<Story> = .idle

    var body: some View {
        Group {
            switch state {
            case .loaded(let story):
                StoryDetailView(story: story)
            case .failed(let message):
                ErrorStateView(title: "Couldn't open the story", message: message) {
                    Task { await load() }
                }
            default:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .brandBackground()
        .task { await load() }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await WordPressClient.shared.story(id: storyID))
        } catch {
            state = .failed(Loadable<Story>.message(for: error))
        }
    }
}

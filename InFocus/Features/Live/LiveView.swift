import SwiftUI

/// Games, concerts and ceremonies: on now, coming up, and replays.
struct LiveView: View {
    @Environment(LiveStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                content.padding(.bottom, 24)
            }
            .brandBackground()
            .readableMargins()
            .navigationTitle("Live")
            .navigationDestination(for: LiveVideo.self) { LivePlayerView(video: $0) }
            .task { await store.load() }
            .refreshable { await store.load(force: true) }
        }
    }

    @ViewBuilder private var content: some View {
        switch store.feed {
        case .idle, .loading:
            VStack(spacing: 16) {
                Skeleton().aspectRatio(16 / 9, contentMode: .fit)
                SkeletonList(rows: 3)
            }
            .padding(Brand.gutter)
        case .failed(let message):
            ErrorStateView(title: "Couldn't load livestreams", message: message) {
                Task { await store.load(force: true) }
            }
        case .loaded(let feed):
            VStack(alignment: .leading, spacing: 28) {
                if feed.live.isEmpty && feed.upcoming.isEmpty && feed.recent.isEmpty {
                    EmptyStateView(title: "No livestreams yet",
                                   message: "Games, concerts and ceremonies InFocus streams will show up here.")
                }
                ForEach(feed.live) { video in
                    NavigationLink(value: video) { LiveNowCard(video: video) }.buttonStyle(.plain)
                }
                if !feed.upcoming.isEmpty { upcoming(feed.upcoming) }
                if !feed.recent.isEmpty { replays(feed.recent) }
            }
            .padding(Brand.gutter)
        }
    }

    private func upcoming(_ streams: [UpcomingStream]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Coming up")
            VStack(spacing: 0) {
                ForEach(streams) { stream in
                    UpcomingRow(stream: stream)
                    if stream.id != streams.last?.id { Divider().overlay(Brand.line) }
                }
            }
            .card(padding: 0)
        }
    }

    private func replays(_ videos: [LiveVideo]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Replays")
            ForEach(videos) { video in
                NavigationLink(value: video) { ReplayRow(video: video) }.buttonStyle(.plain)
                Divider().overlay(Brand.line)
            }
        }
    }
}

/// The stream that's on right now, big.
struct LiveNowCard: View {
    let video: LiveVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Thumbnail(url: video.thumbnailUrl ?? YouTube.thumbnailURL(video.videoId))
                .overlay(alignment: .topLeading) { LiveTag().padding(10) }
                .overlay { PlayBadge() }
            Nameplate(eyebrow: "On now", title: video.title, subtitle: "Tap to watch live")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live now: \(video.title)")
    }
}

/// Date block (mono) + title + place.
private struct UpcomingRow: View {
    let stream: UpcomingStream

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(ShowDate.format(stream.startsAt, "MMM").uppercased())
                    .font(.lexend(10, .medium, relativeTo: .caption2))
                    .tracking(1.2)
                    .foregroundStyle(Brand.green)
                Text(ShowDate.format(stream.startsAt, "d"))
                    .font(.mono(22, medium: true, relativeTo: .title2))
                    .foregroundStyle(Brand.text)
            }
            .frame(width: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(stream.title)
                    .font(.lexend(16, .semibold, relativeTo: .headline))
                    .foregroundStyle(Brand.text)
                Text(([ShowDate.dayAndTime(stream.startsAt)] + [stream.location].compactMap { $0?.nilIfEmpty }).joined(separator: " · "))
                    .font(.small)
                    .foregroundStyle(Brand.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }
}

private struct ReplayRow: View {
    let video: LiveVideo

    var body: some View {
        HStack(spacing: 12) {
            Thumbnail(url: video.thumbnailUrl ?? YouTube.thumbnailURL(video.videoId)).frame(width: 136)
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.lexend(15, .semibold, relativeTo: .headline))
                    .foregroundStyle(Brand.text)
                    .lineLimit(3)
                if let date = video.startedAt {
                    Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.mono(12))
                        .foregroundStyle(Brand.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A flat play mark on a thumbnail.
struct PlayBadge: View {
    var body: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Brand.softWhite)
            .frame(width: 56, height: 56)
            .background(Brand.fill, in: RoundedRectangle(cornerRadius: Brand.radius))
            .accessibilityHidden(true)
    }
}

/// A livestream or replay with the player.
struct LivePlayerView: View {
    let video: LiveVideo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                YouTubePlayer(videoId: video.videoId, autoplay: video.isLive)
                Nameplate(eyebrow: video.isLive ? "Live now" : "Replay", title: video.title, subtitle: subtitle)
                VideoActions(url: YouTube.watchURL(video.videoId), shareTitle: video.title)
                    .padding(Brand.gutter)
            }
        }
        .brandBackground()
        .readableMargins()
        .navigationTitle(video.isLive ? "Live" : "Replay")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subtitle: String? {
        guard !video.isLive, let date = video.startedAt else { return video.isLive ? "Streaming now on YouTube" : nil }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }
}

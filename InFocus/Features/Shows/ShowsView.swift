import SwiftUI

/// Every InFocus News episode, one season at a time.
struct ShowsView: View {
    @Environment(ShowsStore.self) private var store
    @State private var seasonNumber: Int?

    var body: some View {
        NavigationStack {
            content
                .brandBackground()
                .navigationTitle("Shows")
                .navigationDestination(for: Show.self) { ShowDetailView(show: $0) }
                .task { await store.load() }
                .refreshable { await store.load(force: true) }
        }
    }

    @ViewBuilder private var content: some View {
        switch store.feed {
        case .idle, .loading:
            ScrollView { SkeletonList(rows: 7).padding(Brand.gutter) }
        case .failed(let message):
            ScrollView {
                ErrorStateView(title: "Couldn't load shows", message: message) {
                    Task { await store.load(force: true) }
                }
            }
        case .loaded(let feed):
            if feed.seasons.isEmpty {
                ScrollView {
                    EmptyStateView(title: "No shows yet", message: "New episodes appear here after they air.")
                }
            } else {
                seasonList(feed.seasons)
            }
        }
    }

    private func seasonList(_ seasons: [Season]) -> some View {
        let selected = seasons.first { $0.number == seasonNumber } ?? seasons[0]
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                Section {
                    VStack(spacing: 0) {
                        if selected.shows.isEmpty {
                            EmptyStateView(title: "No episodes yet", message: "Season \(selected.number) shows appear here after they air.")
                        }
                        ForEach(selected.shows) { show in
                            NavigationLink(value: show) { ShowRow(show: show) }
                                .buttonStyle(.plain)
                            Divider().overlay(Brand.line)
                        }
                    }
                    .padding(.horizontal, Brand.gutter)
                } header: {
                    SeasonPicker(seasons: seasons, selected: selected.number) { seasonNumber = $0 }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

/// Horizontal season chips, newest first.
private struct SeasonPicker: View {
    let seasons: [Season]
    let selected: Int
    let select: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(seasons) { season in
                    Chip(title: "Season \(season.number)", selected: season.number == selected) {
                        select(season.number)
                    }
                }
            }
            .padding(.horizontal, Brand.gutter)
            .padding(.vertical, 10)
        }
        .background(Brand.background)
    }
}

/// Thumbnail, date and length of one show.
struct ShowRow: View {
    let show: Show

    var body: some View {
        HStack(spacing: 12) {
            Thumbnail(url: show.thumbnailUrl)
                .frame(width: 136)
                .overlay(alignment: .bottomTrailing) {
                    if let duration = show.duration { Tag(text: duration, mono: true).padding(5) }
                }
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("InFocus News", color: Brand.green, size: 10)
                Text(show.displayTitle)
                    .font(.lexend(16, .semibold, relativeTo: .headline))
                    .foregroundStyle(Brand.text)
                    .lineLimit(2)
                if let date = show.publishedAt {
                    Text(date.formatted(.dateTime.year()))
                        .font(.mono(12))
                        .foregroundStyle(Brand.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Plays the show")
    }
}

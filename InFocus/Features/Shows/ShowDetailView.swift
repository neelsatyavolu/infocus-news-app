import SwiftUI

/// One show: the player, its date, and the announcements read on it.
struct ShowDetailView: View {
    let show: Show
    @Environment(ShowsStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                YouTubePlayer(videoId: show.videoId)
                Nameplate(eyebrow: "InFocus News", title: show.displayTitle, subtitle: subtitle)
                VStack(alignment: .leading, spacing: 24) {
                    VideoActions(url: show.watchURL, shareTitle: "InFocus News – \(show.displayTitle)")
                    if let date = show.showDate {
                        AnnouncementsRecap(showDate: date)
                    }
                }
                .padding(Brand.gutter)
            }
        }
        .brandBackground()
        .navigationTitle(show.dateLabel ?? "Show")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: show.showDate) {
            if let date = show.showDate { await store.loadAnnouncements(for: date) }
        }
    }

    private var subtitle: String? {
        [show.publishedAt.map { $0.formatted(.dateTime.year()) }, show.duration]
            .compactMap { $0 }
            .joined(separator: " · ")
            .nilIfEmpty
    }
}

/// "On this show": the bulletin's announcements as a list.
struct AnnouncementsRecap: View {
    let showDate: String
    var title = "Announcements on this show"
    var limit: Int?
    @Environment(ShowsStore.self) private var store

    var body: some View {
        switch store.announcements(for: showDate) {
        case .idle, .loading:
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title)
                Skeleton(height: 64)
                Skeleton(height: 64)
            }
        case .failed:
            EmptyView()
        case .loaded(let items) where items.isEmpty:
            EmptyView()
        case .loaded(let items):
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: title)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(items.prefix(limit ?? items.count).enumerated()), id: \.offset) { _, text in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Rectangle().fill(Brand.green).frame(width: 6, height: 6)
                                .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 2 }
                            Text(text)
                                .font(.bodyText)
                                .foregroundStyle(Brand.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .card()
            }
        }
    }
}
